package com.afab.ai.service;

import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Extracts readable text safely from uploaded business documents (PDF, XLSX, CSV, TXT, JSON, MD)
 * with strict size, page, and XML-entity protections.
 */
@Component
public class AiFileExtractor {

    public static final int MAX_EXTRACTED_CHARS = 14_000;
    private static final int MAX_PDF_PAGES = 25;
    private static final int MAX_ZIP_UNCOMPRESSED_BYTES = 5 * 1024 * 1024;
    private static final int MAX_XLSX_ROWS = 200;

    public String extractText(byte[] bytes, String contentType, String filename) {
        if (bytes == null || bytes.length == 0) {
            return "";
        }
        String ct = contentType != null ? contentType.toLowerCase(Locale.ROOT) : "";
        String lowerName = filename != null ? filename.toLowerCase(Locale.ROOT) : "";

        try {
            if ("application/pdf".equals(ct) || lowerName.endsWith(".pdf")) {
                return truncate(extractPdf(bytes));
            }
            if (ct.contains("spreadsheetml") || lowerName.endsWith(".xlsx")) {
                return truncate(extractXlsx(bytes));
            }
            return truncate(extractPlainUtf8(bytes));
        } catch (Exception e) {
            return "[Document uploaded: " + (filename != null ? filename : "file")
                    + " — text extraction note: " + e.getMessage() + "]";
        }
    }

    private String extractPdf(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        try (PdfReader reader = new PdfReader(new ByteArrayInputStream(bytes))) {
            int pages = Math.min(reader.getNumberOfPages(), MAX_PDF_PAGES);
            PdfTextExtractor extractor = new PdfTextExtractor(reader);
            for (int page = 1; page <= pages; page++) {
                String text = extractor.getTextFromPage(page);
                if (text != null && !text.isBlank()) {
                    if (sb.length() > 0) sb.append("\n\n");
                    sb.append("--- Page ").append(page).append(" ---\n").append(text.trim());
                }
                if (sb.length() >= MAX_EXTRACTED_CHARS) break;
            }
            if (reader.getNumberOfPages() > MAX_PDF_PAGES) {
                sb.append("\n[Truncated after ").append(MAX_PDF_PAGES).append(" pages]");
            }
        } catch (Exception e) {
            return "[Unable to parse PDF text (possibly scanned image-only or encrypted PDF).]";
        }
        String out = sb.toString().trim();
        return out.isEmpty()
                ? "[PDF contains no selectable text layer (it may be a scanned image).]"
                : normalizeWhitespace(out);
    }

    private String extractXlsx(byte[] bytes) throws Exception {
        Map<String, byte[]> entries = new LinkedHashMap<>();
        long totalRead = 0;

        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(bytes))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (entry.isDirectory()) continue;
                String name = entry.getName();
                if (!"xl/sharedStrings.xml".equals(name)
                        && !(name.startsWith("xl/worksheets/sheet") && name.endsWith(".xml"))) {
                    continue;
                }
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                byte[] buf = new byte[4096];
                int n;
                while ((n = zis.read(buf)) > 0) {
                    totalRead += n;
                    if (totalRead > MAX_ZIP_UNCOMPRESSED_BYTES) {
                        throw new IllegalArgumentException("Spreadsheet exceeds safe uncompressed size limit.");
                    }
                    baos.write(buf, 0, n);
                }
                entries.put(name, baos.toByteArray());
            }
        }

        List<String> sharedStrings = entries.containsKey("xl/sharedStrings.xml")
                ? parseSharedStrings(entries.get("xl/sharedStrings.xml"))
                : List.of();

        List<String> sheetKeys = entries.keySet().stream()
                .filter(k -> k.startsWith("xl/worksheets/sheet") && k.endsWith(".xml"))
                .sorted()
                .limit(5)
                .toList();

        if (sheetKeys.isEmpty()) {
            return "[No readable worksheets found in XLSX file.]";
        }

        StringBuilder out = new StringBuilder();
        for (String sheetKey : sheetKeys) {
            String sheetTitle = sheetKey.substring(sheetKey.lastIndexOf('/') + 1, sheetKey.length() - 4);
            out.append("--- Sheet: ").append(sheetTitle).append(" ---\n");
            List<String> rows = parseWorksheetRows(entries.get(sheetKey), sharedStrings);
            for (String row : rows) {
                out.append(row).append('\n');
                if (out.length() >= MAX_EXTRACTED_CHARS) break;
            }
            if (out.length() >= MAX_EXTRACTED_CHARS) break;
        }
        return normalizeWhitespace(out.toString());
    }

    private List<String> parseSharedStrings(byte[] xmlBytes) throws Exception {
        Document doc = newSecureXmlBuilder().parse(new ByteArrayInputStream(xmlBytes));
        NodeList siList = doc.getElementsByTagName("si");
        List<String> values = new ArrayList<>(siList.getLength());
        for (int i = 0; i < siList.getLength(); i++) {
            Element si = (Element) siList.item(i);
            NodeList tNodes = si.getElementsByTagName("t");
            StringBuilder text = new StringBuilder();
            for (int j = 0; j < tNodes.getLength(); j++) {
                text.append(tNodes.item(j).getTextContent());
            }
            values.add(text.toString());
        }
        return values;
    }

    private List<String> parseWorksheetRows(byte[] xmlBytes, List<String> sharedStrings) throws Exception {
        Document doc = newSecureXmlBuilder().parse(new ByteArrayInputStream(xmlBytes));
        NodeList rowNodes = doc.getElementsByTagName("row");
        List<String> outRows = new ArrayList<>();
        int count = Math.min(rowNodes.getLength(), MAX_XLSX_ROWS);
        for (int i = 0; i < count; i++) {
            Element rowEl = (Element) rowNodes.item(i);
            NodeList cellNodes = rowEl.getElementsByTagName("c");
            List<String> cells = new ArrayList<>();
            for (int c = 0; c < cellNodes.getLength(); c++) {
                Element cellEl = (Element) cellNodes.item(c);
                String type = cellEl.getAttribute("t");
                String val = "";
                if ("inlineStr".equals(type)) {
                    NodeList isList = cellEl.getElementsByTagName("t");
                    if (isList.getLength() > 0) val = isList.item(0).getTextContent();
                } else {
                    NodeList vList = cellEl.getElementsByTagName("v");
                    if (vList.getLength() > 0) {
                        String raw = vList.item(0).getTextContent();
                        if ("s".equals(type)) {
                            try {
                                int idx = Integer.parseInt(raw.trim());
                                val = idx >= 0 && idx < sharedStrings.size() ? sharedStrings.get(idx) : raw;
                            } catch (NumberFormatException ignored) {
                                val = raw;
                            }
                        } else {
                            val = raw;
                        }
                    }
                }
                cells.add(val != null ? val.replace('\t', ' ').replace('\n', ' ').trim() : "");
            }
            if (cells.stream().anyMatch(s -> !s.isBlank())) {
                outRows.add(String.join(" | ", cells));
            }
        }
        if (rowNodes.getLength() > MAX_XLSX_ROWS) {
            outRows.add("[Truncated after " + MAX_XLSX_ROWS + " rows]");
        }
        return outRows;
    }

    private javax.xml.parsers.DocumentBuilder newSecureXmlBuilder() throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
        dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        dbf.setExpandEntityReferences(false);
        return dbf.newDocumentBuilder();
    }

    private String extractPlainUtf8(byte[] bytes) {
        for (byte b : bytes) {
            if (b == 0) {
                throw new IllegalArgumentException("Binary file content is not valid UTF-8 text.");
            }
        }
        try {
            String decoded = StandardCharsets.UTF_8.newDecoder()
                    .onMalformedInput(CodingErrorAction.REPORT)
                    .onUnmappableCharacter(CodingErrorAction.REPORT)
                    .decode(ByteBuffer.wrap(bytes))
                    .toString();
            return normalizeWhitespace(decoded);
        } catch (CharacterCodingException e) {
            return normalizeWhitespace(new String(bytes, StandardCharsets.UTF_8));
        }
    }

    private String normalizeWhitespace(String raw) {
        return raw.replace("\r\n", "\n").replace("\r", "\n").trim();
    }

    private String truncate(String s) {
        if (s == null) return "";
        if (s.length() <= MAX_EXTRACTED_CHARS) return s;
        return s.substring(0, MAX_EXTRACTED_CHARS) + "\n...[truncated]";
    }
}
