import 'package:starcitizen_doctor/base/ui.dart';
import 'package:starcitizen_doctor/common/conf.dart';
import 'package:starcitizen_doctor/ui/settings/settings_ui_model.dart';

class SettingUI extends BaseUI<SettingUIModel> {
  @override
  Widget? buildBody(BuildContext context, SettingUIModel model) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (AppConf.isMSE)
            makeSettingsItem(const Icon(FluentIcons.reset_device), "重置自动密码填充",
                subTitle:
                    "启用：${model.isEnableAutoLogin ? "已启用" : "已禁用"}    设备支持：${model.isDeviceSupportWinHello ? "支持" : "不支持"}     邮箱：${model.autoLoginEmail}      密码：${model.isEnableAutoLoginPwd ? "已加密保存" : "未保存"}",
                onTap: model.onResetAutoLogin)
          else
            const Text("暂无设置项"),
        ],
      ),
    );
  }

  Widget makeSettingsItem(Widget icon, String title,
      {String? subTitle, VoidCallback? onTap}) {
    return Button(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Text(title),
                      const Spacer(),
                    ],
                  ),
                  if (subTitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subTitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withOpacity(.6)),
                    )
                  ],
                ],
              ),
            ),
            const Icon(FluentIcons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  String getUITitle(BuildContext context, SettingUIModel model) => "SettingUI";
}
