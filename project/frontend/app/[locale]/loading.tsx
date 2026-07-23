import { AfabLoader } from "@/components/ui/afab-loader";

export default function GlobalLoading() {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-background/80 backdrop-blur-sm">
      <AfabLoader size="lg" text="Loading AFAB workspace..." />
    </div>
  );
}
