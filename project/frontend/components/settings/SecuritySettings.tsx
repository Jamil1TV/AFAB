"use client";

import { useTranslations } from "next-intl";
import { useState, useEffect } from "react";
import { SettingsService } from "@/lib/api/settings";
import { AuthService, TwoFactorSetupData, SessionDto } from "@/lib/api/auth";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { 
  CheckCircle2, ShieldCheck, Key, Lock, 
  Smartphone, Monitor, Laptop, Globe, LogOut, Bell,
  Copy, Check, Download, RefreshCw, AlertTriangle
} from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { InputOTP, InputOTPGroup, InputOTPSlot } from "@/components/ui/input-otp";
import { PageHeader } from "@/components/dashboard/PageHeader";
import { QRCodeSVG } from "qrcode.react";
import { toast } from "sonner";

export function SecuritySettings({ profile }: { profile: any }) {
  const t = useTranslations("settings");
  
  const [sessions, setSessions] = useState<SessionDto[]>([]);
  const [isLoadingSessions, setIsLoadingSessions] = useState(true);
  const [twoFactorEnabled, setTwoFactorEnabled] = useState(!!profile?.twoFactorEnabled);
  
  // Password change state
  const [pwdData, setPwdData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [pwdLoading, setPwdLoading] = useState(false);
  const [pwdError, setPwdError] = useState("");
  const [pwdSuccess, setPwdSuccess] = useState(false);
  const [isPwdModalOpen, setIsPwdModalOpen] = useState(false);

  // 2FA Setup state
  const [isSetupModalOpen, setIsSetupModalOpen] = useState(false);
  const [setupStep, setSetupStep] = useState<1 | 2 | 3>(1);
  const [setupData, setSetupData] = useState<TwoFactorSetupData | null>(null);
  const [setupCode, setSetupCode] = useState("");
  const [setupLoading, setSetupLoading] = useState(false);
  const [setupError, setSetupError] = useState("");
  const [copiedSecret, setCopiedSecret] = useState(false);
  const [copiedCodes, setCopiedCodes] = useState(false);

  // 2FA Manage / Disable state
  const [isManageModalOpen, setIsManageModalOpen] = useState(false);
  const [disablePassword, setDisablePassword] = useState("");
  const [disableLoading, setDisableLoading] = useState(false);
  const [disableError, setDisableError] = useState("");
  const [regeneratedCodes, setRegeneratedCodes] = useState<string[] | null>(null);
  const [regeneratingCodes, setRegeneratingCodes] = useState(false);

  const fetchSessions = async () => {
    try {
      const data = await AuthService.getActiveSessions();
      setSessions(data);
    } catch (err) {
      console.error("Failed to load sessions:", err);
    } finally {
      setIsLoadingSessions(false);
    }
  };

  useEffect(() => {
    fetchSessions();
  }, []);

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    setPwdError("");
    setPwdSuccess(false);

    if (pwdData.newPassword !== pwdData.confirmPassword) {
      setPwdError(t("security.passwordMismatch"));
      return;
    }

    setPwdLoading(true);
    try {
      await SettingsService.changePassword(pwdData.currentPassword, pwdData.newPassword);
      setPwdSuccess(true);
      toast.success(t("security.passwordChanged"));
      setTimeout(() => {
        setIsPwdModalOpen(false);
        setPwdData({ currentPassword: "", newPassword: "", confirmPassword: "" });
        setPwdSuccess(false);
      }, 1500);
    } catch (err: any) {
      setPwdError(err.message || "Failed to change password");
    } finally {
      setPwdLoading(false);
    }
  };

  const handleStartSetup2FA = async () => {
    setSetupLoading(true);
    setSetupError("");
    setSetupStep(1);
    setSetupCode("");
    try {
      const data = await AuthService.setup2FA();
      setSetupData(data);
      setIsSetupModalOpen(true);
    } catch (err: any) {
      toast.error(err.message || "Failed to initiate 2FA setup");
    } finally {
      setSetupLoading(false);
    }
  };

  const handleVerifyAndEnable2FA = async () => {
    if (!setupData || setupCode.length !== 6) return;
    setSetupLoading(true);
    setSetupError("");
    try {
      await AuthService.enable2FA({
        secret: setupData.secret,
        code: setupCode,
        backupCodes: setupData.backupCodes,
      });
      setTwoFactorEnabled(true);
      setSetupStep(3);
      toast.success(t("security.twoFactorEnabled"));
    } catch (err: any) {
      setSetupError(err.message || "Invalid verification code");
    } finally {
      setSetupLoading(false);
    }
  };

  const handleDisable2FA = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!disablePassword) return;
    setDisableLoading(true);
    setDisableError("");
    try {
      await AuthService.disable2FA({ password: disablePassword });
      setTwoFactorEnabled(false);
      setIsManageModalOpen(false);
      setDisablePassword("");
      toast.success(t("security.disabled"));
    } catch (err: any) {
      setDisableError(err.message || "Incorrect password");
    } finally {
      setDisableLoading(false);
    }
  };

  const handleRegenerateBackupCodes = async () => {
    setRegeneratingCodes(true);
    try {
      const codes = await AuthService.regenerateBackupCodes();
      setRegeneratedCodes(codes);
      toast.success(t("security.regenerateCodes"));
    } catch (err: any) {
      toast.error(err.message || "Failed to regenerate backup codes");
    } finally {
      setRegeneratingCodes(false);
    }
  };

  const handleCopySecret = () => {
    if (!setupData?.secret) return;
    navigator.clipboard.writeText(setupData.secret);
    setCopiedSecret(true);
    setTimeout(() => setCopiedSecret(false), 2000);
  };

  const handleCopyBackupCodes = (codes: string[]) => {
    navigator.clipboard.writeText(codes.join("\n"));
    setCopiedCodes(true);
    setTimeout(() => setCopiedCodes(false), 2000);
  };

  const handleDownloadBackupCodes = (codes: string[]) => {
    const text = `AFAB Finance - Emergency Recovery Backup Codes\nGenerated: ${new Date().toISOString()}\n\n` +
      codes.map((c, i) => `${i + 1}. ${c}`).join("\n") +
      `\n\nEach backup code can only be used once. Keep them in a secure location.`;
    const blob = new Blob([text], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `afab-backup-codes-${new Date().toISOString().slice(0, 10)}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleRevokeSession = async (tokenId: string) => {
    try {
      await AuthService.revokeSession(tokenId);
      setSessions(prev => prev.filter(s => s.id !== tokenId));
      toast.success(t("security.logOut"));
    } catch (err: any) {
      toast.error(err.message || "Failed to revoke session");
    }
  };

  const handleRevokeAll = async () => {
    try {
      await AuthService.revokeAllOtherSessions();
      fetchSessions();
      toast.success(t("security.logOutAll"));
    } catch (err: any) {
      toast.error(err.message || "Failed to revoke sessions");
    }
  };

  const getDeviceIcon = (deviceInfo: string) => {
    const info = deviceInfo?.toLowerCase() || "";
    if (info.includes("mobile") || info.includes("iphone") || info.includes("android")) return <Smartphone className="w-5 h-5 text-gray-400" />;
    if (info.includes("mac") || info.includes("windows") || info.includes("linux")) return <Laptop className="w-5 h-5 text-gray-400" />;
    return <Monitor className="w-5 h-5 text-gray-400" />;
  };

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
      {/* Left Form Content */}
      <div className="xl:col-span-2 space-y-8">
        <PageHeader
          title={t("security.title")}
          subtitle={t("security.subtitle")}
        />

        {/* Security Overview */}
        <div className="afab-card p-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 bg-emerald-500/10 rounded-2xl flex items-center justify-center shrink-0">
              <ShieldCheck className="w-6 h-6 text-emerald-600 dark:text-emerald-400" />
            </div>
            <div>
              <h3 className="afab-card-title">{t("security.accountSecure")}</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">{t("security.accountSecureDesc")}</p>
            </div>
          </div>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="afab-inset flex items-center gap-3 p-3.5">
              <div className={`w-2.5 h-2.5 rounded-full ${twoFactorEnabled ? 'bg-emerald-500' : 'bg-amber-500'}`} />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {t("security.twoFactor")}: {twoFactorEnabled ? t("security.enabled") : t("security.disabled")}
              </span>
            </div>
            <div className="afab-inset flex items-center gap-3 p-3.5">
              <div className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{t("security.strongPassword")}</span>
            </div>
            <div className="afab-inset flex items-center gap-3 p-3.5">
              <div className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{t("security.loginAlerts")}</span>
            </div>
            <div className="afab-inset flex items-center gap-3 p-3.5">
              <div className="w-2.5 h-2.5 rounded-full bg-sky-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {sessions.length} {t("security.activeSessions")}
              </span>
            </div>
          </div>
        </div>

        {/* Password & Authentication */}
        <div className="afab-card divide-y divide-gray-100 dark:divide-gray-800/60">
          
          {/* Password */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="afab-icon-tile">
                <Key className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{t("security.password")}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">{t("security.passwordSubtitle")}</p>
                <div className="flex flex-wrap items-center gap-4 text-xs">
                  <span className="text-gray-500 dark:text-gray-400">
                    {t("security.lastChanged")}: {profile?.passwordChangedAt ? new Date(profile.passwordChangedAt).toLocaleDateString() : "Never"}
                  </span>
                  <span className="flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400 font-semibold">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    {t("security.strong")}
                  </span>
                </div>
              </div>
            </div>
            <Dialog open={isPwdModalOpen} onOpenChange={setIsPwdModalOpen}>
              <DialogTrigger render={<Button variant="outline" className="afab-btn-secondary shrink-0">{t("security.changePassword")}</Button>} />
              <DialogContent className="sm:max-w-[425px] rounded-3xl border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 sm:p-8 shadow-2xl">
                <DialogHeader>
                  <DialogTitle className="afab-card-title">{t("security.changePassword")}</DialogTitle>
                </DialogHeader>
                <form onSubmit={handlePasswordChange} className="space-y-4 pt-4">
                  {pwdError && (
                    <div className="p-3 bg-red-50 dark:bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 rounded-xl text-sm">
                      {pwdError}
                    </div>
                  )}
                  {pwdSuccess && (
                    <div className="p-3 bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 dark:text-emerald-400 rounded-xl text-sm">
                      {t("security.passwordChanged")}
                    </div>
                  )}
                  <div className="space-y-2">
                    <Label className="afab-label">{t("security.currentPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      className="afab-input"
                      value={pwdData.currentPassword}
                      onChange={e => setPwdData({...pwdData, currentPassword: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="afab-label">{t("security.newPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      className="afab-input"
                      value={pwdData.newPassword}
                      onChange={e => setPwdData({...pwdData, newPassword: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label className="afab-label">{t("security.confirmPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      className="afab-input"
                      value={pwdData.confirmPassword}
                      onChange={e => setPwdData({...pwdData, confirmPassword: e.target.value})}
                    />
                  </div>
                  <div className="pt-4 flex justify-end">
                    <Button type="submit" disabled={pwdLoading} className="afab-btn-primary w-full sm:w-auto">
                      {pwdLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
                    </Button>
                  </div>
                </form>
              </DialogContent>
            </Dialog>
          </div>

          {/* 2FA Setup & Management */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="afab-icon-tile">
                <Lock className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{t("security.twoFactorTitle")}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">{t("security.twoFactorSubtitle")}</p>
                {twoFactorEnabled ? (
                   <span className="afab-badge afab-badge-success">
                     {t("security.enabled")}
                   </span>
                ) : (
                  <span className="afab-badge afab-badge-neutral">
                     {t("security.disabled")}
                   </span>
                )}
              </div>
            </div>

            {twoFactorEnabled ? (
              <Button 
                variant="outline" 
                onClick={() => {
                  setDisablePassword("");
                  setDisableError("");
                  setRegeneratedCodes(null);
                  setIsManageModalOpen(true);
                }}
                className="afab-btn-secondary shrink-0"
              >
                {t("security.manage2FA")}
              </Button>
            ) : (
              <Button 
                onClick={handleStartSetup2FA}
                disabled={setupLoading}
                className="afab-btn-primary shrink-0"
              >
                {setupLoading ? <AfabLoader size="xs" /> : t("security.enable2FA")}
              </Button>
            )}
          </div>

          {/* Login Alerts */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="afab-icon-tile">
                <Bell className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{t("security.loginAlertsTitle")}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">{t("security.loginAlertsSubtitle")}</p>
              </div>
            </div>
            <Switch defaultChecked />
          </div>

        </div>

        {/* Active Sessions */}
        <div className="afab-card overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-800/60 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="afab-card-title mb-1">{t("security.sessionsTitle")}</h3>
              <p className="text-sm text-gray-500 dark:text-gray-400">{t("security.sessionsSubtitle")}</p>
            </div>
            <Button 
              variant="outline" 
              onClick={handleRevokeAll} 
              className="afab-btn-secondary shrink-0 !text-red-600 dark:!text-red-400 hover:!bg-red-50 dark:hover:!bg-red-500/10"
            >
              {t("security.logOutAll")}
            </Button>
          </div>
          
          <div className="overflow-x-auto">
            <table className="afab-table whitespace-nowrap">
              <thead className="afab-thead">
                <tr>
                  <th className="afab-th">{t("security.device")}</th>
                  <th className="afab-th">{t("security.ipAddress")}</th>
                  <th className="afab-th">{t("security.lastActive")}</th>
                  <th className="afab-th">{t("security.status")}</th>
                  <th className="afab-th text-end">{t("security.action")}</th>
                </tr>
              </thead>
              <tbody className="afab-tbody">
                {isLoadingSessions ? (
                   <tr>
                     <td colSpan={5} className="afab-td py-8 text-center">
                       <AfabLoader size="sm" />
                     </td>
                   </tr>
                ) : sessions.length === 0 ? (
                   <tr>
                     <td colSpan={5} className="afab-td py-8 text-center text-gray-500 dark:text-gray-400">
                       No active sessions found.
                     </td>
                   </tr>
                ) : (
                  sessions.map((session) => (
                    <tr key={session.id} className="afab-tr group">
                      <td className="afab-td">
                        <div className="flex items-center gap-3">
                          {getDeviceIcon(session.deviceInfo)}
                          <span className="font-medium text-gray-900 dark:text-white">{session.deviceInfo || "Unknown Device"}</span>
                        </div>
                      </td>
                      <td className="afab-td">
                        <div className="flex items-center gap-2 text-gray-500 dark:text-gray-400">
                          <Globe className="w-4 h-4" />
                          {session.ipAddress || "Unknown IP"}
                        </div>
                      </td>
                      <td className="afab-td text-gray-500 dark:text-gray-400">
                        {new Date(session.createdAt).toLocaleDateString()}
                      </td>
                      <td className="afab-td">
                        {session.currentSession ? (
                          <span className="afab-badge afab-badge-success">
                            {t("security.currentSession")}
                          </span>
                        ) : (
                          <span className="afab-badge afab-badge-neutral">
                            {t("security.active")}
                          </span>
                        )}
                      </td>
                      <td className="afab-td text-end">
                        {!session.currentSession && (
                          <button 
                            onClick={() => handleRevokeSession(session.id)}
                            className="afab-icon-btn hover:!text-red-600 dark:hover:!text-red-400"
                            title={t("security.logOut")}
                          >
                            <LogOut className="w-4 h-4" />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Right Sidebar Content */}
      <div className="space-y-6">
        {/* Tips */}
        <div className="afab-card p-6">
          <h3 className="afab-card-title mb-1">{t("security.tips")}</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-6">{t("security.tipsSubtitle")}</p>
          
          <div className="space-y-5">
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip1Title")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("security.tip1Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip2Title")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("security.tip2Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-gray-300 dark:text-gray-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip3Title")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("security.tip3Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip4Title")}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t("security.tip4Desc")}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Support */}
        <div className="afab-card p-6 text-center">
          <div className="w-12 h-12 bg-[var(--primary)]/10 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <ShieldCheck className="w-6 h-6 text-[var(--primary-hover)] dark:text-[var(--primary)]" />
          </div>
          <h3 className="afab-card-title mb-2">{t("security.needHelp")}</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400 mb-6 leading-relaxed">
            {t("security.needHelpDesc")}
          </p>
          <Button variant="outline" className="afab-btn-secondary w-full">
            {t("security.contactSupport")}
          </Button>
        </div>
      </div>

      {/* 2FA Setup Modal */}
      <Dialog open={isSetupModalOpen} onOpenChange={setIsSetupModalOpen}>
        <DialogContent className="sm:max-w-[480px] rounded-3xl border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 sm:p-8 shadow-2xl">
          <DialogHeader>
            <DialogTitle className="afab-card-title flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-[var(--primary)]" />
              {t("security.setup2FATitle")}
            </DialogTitle>
          </DialogHeader>

          {setupStep === 1 && setupData && (
            <div className="space-y-5 pt-2">
              <div>
                <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                  {t("security.setup2FAStep1")}
                </h4>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {t("security.setup2FAStep1Desc")}
                </p>
              </div>

              {/* QR Code */}
              <div className="flex justify-center p-4 bg-white rounded-2xl border border-gray-200 shadow-sm mx-auto w-fit">
                <QRCodeSVG value={setupData.qrCodeUri} size={180} level="M" />
              </div>

              {/* Manual Secret Key */}
              <div>
                <label className="afab-label">
                  {t("security.cantScanQr")}
                </label>
                <div className="flex items-center gap-2">
                  <input
                    readOnly
                    value={setupData.secret}
                    className="afab-input font-mono text-xs"
                  />
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={handleCopySecret}
                    className="afab-btn-secondary"
                  >
                    {copiedSecret ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedSecret ? t("security.copied") : t("security.copySecret")}
                  </Button>
                </div>
              </div>

              <div className="pt-2 flex justify-end">
                <Button 
                  onClick={() => setSetupStep(2)}
                  className="afab-btn-primary w-full"
                >
                  {t("security.setup2FAStep2")}
                </Button>
              </div>
            </div>
          )}

          {setupStep === 2 && (
            <div className="space-y-5 pt-2">
              <div>
                <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                  {t("security.setup2FAStep2")}
                </h4>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {t("security.setup2FAStep2Desc")}
                </p>
              </div>

              {setupError && (
                <div className="p-3 bg-red-50 dark:bg-red-500/10 border border-red-500/20 text-red-600 dark:text-red-400 rounded-xl text-xs flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  {setupError}
                </div>
              )}

              <div className="flex justify-center py-4">
                <InputOTP
                  maxLength={6}
                  value={setupCode}
                  onChange={(val) => setSetupCode(val)}
                  disabled={setupLoading}
                  autoFocus
                >
                  <InputOTPGroup className="gap-2">
                    <InputOTPSlot index={0} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                    <InputOTPSlot index={1} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                    <InputOTPSlot index={2} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                    <InputOTPSlot index={3} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                    <InputOTPSlot index={4} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                    <InputOTPSlot index={5} className="h-12 w-11 rounded-xl text-lg font-bold border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-[#080c18] text-gray-900 dark:text-white" />
                  </InputOTPGroup>
                </InputOTP>
              </div>

              <div className="flex gap-3 justify-end pt-2">
                <Button variant="outline" className="afab-btn-secondary" onClick={() => setSetupStep(1)}>
                  Back
                </Button>
                <Button
                  onClick={handleVerifyAndEnable2FA}
                  disabled={setupLoading || setupCode.length !== 6}
                  className="afab-btn-primary flex-1"
                >
                  {setupLoading ? <AfabLoader size="xs" /> : t("security.verifyAndEnable")}
                </Button>
              </div>
            </div>
          )}

          {setupStep === 3 && setupData && (
            <div className="space-y-5 pt-2">
              <div className="flex items-center gap-2 p-3 bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-500/20 text-emerald-700 dark:text-emerald-400 rounded-xl text-sm">
                <CheckCircle2 className="w-5 h-5 shrink-0" />
                <span>{t("security.twoFactorEnabled")}</span>
              </div>

              <div>
                <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                  {t("security.setup2FAStep3")}
                </h4>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {t("security.setup2FAStep3Desc")}
                </p>
              </div>

              {/* Codes Grid */}
              <div className="afab-inset grid grid-cols-2 gap-2 p-4">
                {setupData.backupCodes.map((code, idx) => (
                  <div key={idx} className="font-mono text-center text-xs py-1.5 px-2 bg-white dark:bg-[#0c101c] rounded-lg border border-gray-200 dark:border-gray-800/60 font-semibold tracking-wider text-gray-800 dark:text-gray-200">
                    {code}
                  </div>
                ))}
              </div>

              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => handleCopyBackupCodes(setupData.backupCodes)}
                  className="afab-btn-secondary flex-1"
                >
                  {copiedCodes ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                  {copiedCodes ? t("security.copied") : t("security.copyAllCodes")}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => handleDownloadBackupCodes(setupData.backupCodes)}
                  className="afab-btn-secondary flex-1"
                >
                  <Download className="w-3.5 h-3.5" />
                  {t("security.downloadCodes")}
                </Button>
              </div>

              <div className="pt-2">
                <Button
                  onClick={() => setIsSetupModalOpen(false)}
                  className="afab-btn-primary w-full"
                >
                  {t("security.done")}
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* 2FA Manage / Disable Modal */}
      <Dialog open={isManageModalOpen} onOpenChange={setIsManageModalOpen}>
        <DialogContent className="sm:max-w-[480px] rounded-3xl border-gray-200 dark:border-gray-800/80 bg-white dark:bg-[#0c101c] p-6 sm:p-8 shadow-2xl">
          <DialogHeader>
            <DialogTitle className="afab-card-title flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-emerald-500" />
              {t("security.manage2FA")}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-6 pt-2">
            {/* Backup Codes Section */}
            <div className="afab-inset p-4 space-y-3">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div>
                  <h4 className="text-sm font-semibold text-gray-900 dark:text-white">
                    {t("security.setup2FAStep3")}
                  </h4>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    Generate new recovery codes if you have lost or used your current ones.
                  </p>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={handleRegenerateBackupCodes}
                  disabled={regeneratingCodes}
                  className="afab-btn-secondary shrink-0"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${regeneratingCodes ? "animate-spin" : ""}`} />
                  {t("security.regenerateCodes")}
                </Button>
              </div>

              {regeneratedCodes && (
                <div className="pt-2 space-y-3">
                  <div className="grid grid-cols-2 gap-2 bg-white dark:bg-[#0c101c] p-3 rounded-xl border border-gray-200 dark:border-gray-800/60">
                    {regeneratedCodes.map((code, idx) => (
                      <div key={idx} className="font-mono text-center text-xs py-1 px-2 bg-gray-50 dark:bg-[#080c18] rounded-lg font-semibold tracking-wider text-gray-800 dark:text-gray-200">
                        {code}
                      </div>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => handleCopyBackupCodes(regeneratedCodes)}
                      className="afab-btn-secondary flex-1"
                    >
                      <Copy className="w-3 h-3" />
                      {t("security.copyAllCodes")}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => handleDownloadBackupCodes(regeneratedCodes)}
                      className="afab-btn-secondary flex-1"
                    >
                      <Download className="w-3 h-3" />
                      {t("security.downloadCodes")}
                    </Button>
                  </div>
                </div>
              )}
            </div>

            {/* Disable 2FA Section */}
            <form onSubmit={handleDisable2FA} className="p-4 rounded-2xl border border-red-500/20 bg-red-50/50 dark:bg-red-500/5 space-y-3">
              <div>
                <h4 className="text-sm font-semibold text-red-700 dark:text-red-400 flex items-center gap-1.5">
                  <AlertTriangle className="w-4 h-4" />
                  {t("security.disable2FATitle")}
                </h4>
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                  {t("security.disable2FADesc")}
                </p>
              </div>

              {disableError && (
                <div className="p-2.5 bg-red-50 dark:bg-red-500/10 border border-red-500/20 text-red-700 dark:text-red-300 rounded-xl text-xs">
                  {disableError}
                </div>
              )}

              <div className="space-y-2">
                <Input
                  type="password"
                  placeholder="Enter current password"
                  value={disablePassword}
                  onChange={e => setDisablePassword(e.target.value)}
                  className="afab-input text-xs"
                  required
                />
              </div>

              <Button
                type="submit"
                variant="destructive"
                disabled={disableLoading || !disablePassword}
                className="afab-btn-danger w-full"
              >
                {disableLoading ? <AfabLoader size="xs" /> : t("security.disableConfirm")}
              </Button>
            </form>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
