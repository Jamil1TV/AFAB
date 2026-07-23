"use client";

import { useTranslations } from "next-intl";
import { useState, useEffect } from "react";
import { SettingsService } from "@/lib/api/settings";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AfabLoader } from "@/components/ui/afab-loader";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { 
  AlertCircle, CheckCircle2, ShieldCheck, Key, Lock, 
  Smartphone, Monitor, Laptop, Globe, LogOut, Bell
} from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";

export function SecuritySettings({ profile }: { profile: any }) {
  const t = useTranslations("settings");
  
  const [sessions, setSessions] = useState<any[]>([]);
  const [isLoadingSessions, setIsLoadingSessions] = useState(true);
  
  const [pwdData, setPwdData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [pwdLoading, setPwdLoading] = useState(false);
  const [pwdError, setPwdError] = useState("");
  const [pwdSuccess, setPwdSuccess] = useState(false);
  const [isPwdModalOpen, setIsPwdModalOpen] = useState(false);

  useEffect(() => {
    fetchSessions();
  }, []);

  const fetchSessions = async () => {
    try {
      const data = await SettingsService.getSessions();
      setSessions(data);
    } catch (err) {
      console.error("Failed to load sessions:", err);
    } finally {
      setIsLoadingSessions(false);
    }
  };

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
      setTimeout(() => {
        setIsPwdModalOpen(false);
        setPwdData({ currentPassword: "", newPassword: "", confirmPassword: "" });
        setPwdSuccess(false);
      }, 2000);
    } catch (err: any) {
      setPwdError(err.message || "Failed to change password");
    } finally {
      setPwdLoading(false);
    }
  };

  const handleRevokeSession = async (tokenId: string) => {
    try {
      await SettingsService.revokeSession(tokenId);
      setSessions(sessions.filter(s => s.id !== tokenId));
    } catch (err) {
      console.error("Failed to revoke session", err);
    }
  };

  const handleRevokeAll = async () => {
    try {
      await SettingsService.revokeAllSessions();
      fetchSessions();
    } catch (err) {
      console.error("Failed to revoke all sessions", err);
    }
  };

  const getDeviceIcon = (deviceInfo: string) => {
    const info = deviceInfo?.toLowerCase() || "";
    if (info.includes("mobile") || info.includes("iphone") || info.includes("android")) return <Smartphone className="w-5 h-5 text-gray-400" />;
    if (info.includes("mac") || info.includes("windows")) return <Laptop className="w-5 h-5 text-gray-400" />;
    return <Monitor className="w-5 h-5 text-gray-400" />;
  };

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
      {/* Left Form Content */}
      <div className="xl:col-span-2 space-y-8">
        <div>
          <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-1">
            {t("security.title")}
          </h2>
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            {t("security.subtitle")}
          </p>
        </div>

        {/* Security Overview */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 bg-green-50 dark:bg-green-900/20 rounded-full flex items-center justify-center">
              <ShieldCheck className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 dark:text-white">{t("security.accountSecure")}</h3>
              <p className="text-sm text-gray-500">{t("security.accountSecureDesc")}</p>
            </div>
          </div>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
              <div className={`w-2 h-2 rounded-full ${profile?.twoFactorEnabled ? 'bg-green-500' : 'bg-amber-500'}`} />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{t("security.twoFactor")}</span>
            </div>
            <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
              <div className="w-2 h-2 rounded-full bg-green-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{t("security.strongPassword")}</span>
            </div>
            <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
              <div className="w-2 h-2 rounded-full bg-green-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">{t("security.loginAlerts")}</span>
            </div>
            <div className="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
              <div className="w-2 h-2 rounded-full bg-blue-500" />
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                {sessions.length} {t("security.activeSessions")}
              </span>
            </div>
          </div>
        </div>

        {/* Password & Authentication */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 divide-y divide-gray-100 dark:divide-gray-700">
          
          {/* Password */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 bg-gray-50 dark:bg-gray-900 rounded-lg flex items-center justify-center shrink-0">
                <Key className="w-5 h-5 text-gray-500" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900 dark:text-white mb-1">{t("security.password")}</h3>
                <p className="text-sm text-gray-500 mb-2">{t("security.passwordSubtitle")}</p>
                <div className="flex items-center gap-4 text-xs">
                  <span className="text-gray-500">
                    {t("security.lastChanged")}: {profile?.passwordChangedAt ? new Date(profile.passwordChangedAt).toLocaleDateString() : "Never"}
                  </span>
                  <span className="flex items-center gap-1.5 text-green-600 dark:text-green-400">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    {t("security.strong")}
                  </span>
                </div>
              </div>
            </div>
            <Dialog open={isPwdModalOpen} onOpenChange={setIsPwdModalOpen}>
              <DialogTrigger>
                <Button variant="outline" className="shrink-0">{t("security.changePassword")}</Button>
              </DialogTrigger>
              <DialogContent className="sm:max-w-[425px]">
                <DialogHeader>
                  <DialogTitle>{t("security.changePassword")}</DialogTitle>
                </DialogHeader>
                <form onSubmit={handlePasswordChange} className="space-y-4 pt-4">
                  {pwdError && (
                    <div className="p-3 bg-red-50 text-red-600 rounded-md text-sm">
                      {pwdError}
                    </div>
                  )}
                  {pwdSuccess && (
                    <div className="p-3 bg-green-50 text-green-600 rounded-md text-sm">
                      {t("security.passwordChanged")}
                    </div>
                  )}
                  <div className="space-y-2">
                    <Label>{t("security.currentPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      value={pwdData.currentPassword}
                      onChange={e => setPwdData({...pwdData, currentPassword: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>{t("security.newPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      value={pwdData.newPassword}
                      onChange={e => setPwdData({...pwdData, newPassword: e.target.value})}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label>{t("security.confirmPassword")}</Label>
                    <Input 
                      type="password" 
                      required 
                      value={pwdData.confirmPassword}
                      onChange={e => setPwdData({...pwdData, confirmPassword: e.target.value})}
                    />
                  </div>
                  <div className="pt-4 flex justify-end">
                    <Button type="submit" disabled={pwdLoading} className="w-full sm:w-auto">
                      {pwdLoading ? <AfabLoader size="sm" /> : t("saveChanges")}
                    </Button>
                  </div>
                </form>
              </DialogContent>
            </Dialog>
          </div>

          {/* 2FA */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 bg-gray-50 dark:bg-gray-900 rounded-lg flex items-center justify-center shrink-0">
                <Lock className="w-5 h-5 text-gray-500" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900 dark:text-white mb-1">{t("security.twoFactorTitle")}</h3>
                <p className="text-sm text-gray-500 mb-2">{t("security.twoFactorSubtitle")}</p>
                {profile?.twoFactorEnabled ? (
                   <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400 ring-1 ring-inset ring-green-600/20">
                     {t("security.enabled")}
                   </span>
                ) : (
                  <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400 ring-1 ring-inset ring-gray-500/10">
                     {t("security.disabled")}
                   </span>
                )}
              </div>
            </div>
            <Button variant="outline" className="shrink-0">{t("security.manage2FA")}</Button>
          </div>

          {/* Login Alerts */}
          <div className="p-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 bg-gray-50 dark:bg-gray-900 rounded-lg flex items-center justify-center shrink-0">
                <Bell className="w-5 h-5 text-gray-500" />
              </div>
              <div>
                <h3 className="font-medium text-gray-900 dark:text-white mb-1">{t("security.loginAlertsTitle")}</h3>
                <p className="text-sm text-gray-500">{t("security.loginAlertsSubtitle")}</p>
              </div>
            </div>
            <Switch defaultChecked />
          </div>

        </div>

        {/* Active Sessions */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="font-semibold text-gray-900 dark:text-white mb-1">{t("security.sessionsTitle")}</h3>
              <p className="text-sm text-gray-500">{t("security.sessionsSubtitle")}</p>
            </div>
            <Button variant="outline" onClick={handleRevokeAll} className="shrink-0 text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20">
              {t("security.logOutAll")}
            </Button>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
              <thead className="bg-gray-50/50 dark:bg-gray-900/50 text-gray-500">
                <tr>
                  <th className="px-6 py-4 font-medium">{t("security.device")}</th>
                  <th className="px-6 py-4 font-medium">{t("security.ipAddress")}</th>
                  <th className="px-6 py-4 font-medium">{t("security.lastActive")}</th>
                  <th className="px-6 py-4 font-medium">{t("security.status")}</th>
                  <th className="px-6 py-4 font-medium text-right">{t("security.action")}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                {isLoadingSessions ? (
                   <tr>
                     <td colSpan={5} className="px-6 py-8 text-center">
                       <AfabLoader size="sm" />
                     </td>
                   </tr>
                ) : sessions.length === 0 ? (
                   <tr>
                     <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                       No active sessions found.
                     </td>
                   </tr>
                ) : (
                  sessions.map((session) => (
                    <tr key={session.id} className="group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          {getDeviceIcon(session.deviceInfo)}
                          <span className="font-medium text-gray-900 dark:text-white">{session.deviceInfo || "Unknown Device"}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 text-gray-500">
                          <Globe className="w-4 h-4" />
                          {session.ipAddress || "Unknown"}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-500">
                        {new Date(session.createdAt).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        {session.currentSession ? (
                          <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-400 ring-1 ring-inset ring-green-600/20">
                            {t("security.currentSession")}
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400 ring-1 ring-inset ring-gray-500/10">
                            {t("security.active")}
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        {!session.currentSession && (
                          <button 
                            onClick={() => handleRevokeSession(session.id)}
                            className="text-gray-400 hover:text-red-600 transition-colors p-2"
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
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 className="font-semibold text-gray-900 dark:text-white mb-2">{t("security.tips")}</h3>
          <p className="text-xs text-gray-500 mb-6">{t("security.tipsSubtitle")}</p>
          
          <div className="space-y-5">
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-green-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip1Title")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("security.tip1Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-green-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip2Title")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("security.tip2Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-gray-300 dark:text-gray-600" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip3Title")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("security.tip3Desc")}</p>
              </div>
            </div>
            <div className="flex gap-3">
              <div className="mt-0.5">
                <CheckCircle2 className="w-4 h-4 text-green-500" />
              </div>
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">{t("security.tip4Title")}</p>
                <p className="text-xs text-gray-500 mt-1">{t("security.tip4Desc")}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Support */}
        <div className="bg-primary/5 dark:bg-primary/10 rounded-xl border border-primary/10 p-6 text-center">
          <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-4">
            <ShieldCheck className="w-6 h-6 text-primary" />
          </div>
          <h3 className="font-semibold text-gray-900 dark:text-white mb-2">{t("security.needHelp")}</h3>
          <p className="text-xs text-gray-600 dark:text-gray-400 mb-6 leading-relaxed">
            {t("security.needHelpDesc")}
          </p>
          <Button variant="outline" className="w-full bg-white dark:bg-gray-800">
            {t("security.contactSupport")}
          </Button>
        </div>

      </div>
    </div>
  );
}
