import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:starcitizen_doctor/base/ui.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'game_doctor_ui_model.dart';

class GameDoctorUI extends BaseUI<GameDoctorUIModel> {
  @override
  Widget? buildBody(BuildContext context, GameDoctorUIModel model) {
    return makeDefaultPage(context, model,
        content: Stack(
          children: [
            Column(
              children: [
                if (model.isChecking)
                  Expanded(
                      child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ProgressRing(),
                        const SizedBox(height: 12),
                        Text(model.lastScreenInfo)
                      ],
                    ),
                  ))
                else if (model.checkResult == null ||
                    model.checkResult!.isEmpty) ...[
                  const Expanded(
                      child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 12),
                        Text("扫描完毕，没有找到问题！", maxLines: 1),
                        SizedBox(height: 64),
                      ],
                    ),
                  ))
                ] else
                  ...makeResult(context, model),
              ],
            ),
            if (model.isFixing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(150),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ProgressRing(),
                      const SizedBox(height: 12),
                      Text(model.isFixingString.isNotEmpty
                          ? model.isFixingString
                          : "正在处理..."),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 20,
              right: 20,
              child: makeRescueBanner(context),
            )
          ],
        ));
  }

  List<Widget> makeResult(BuildContext context, GameDoctorUIModel model) {
    return [
      const SizedBox(height: 24),
      Text(model.lastScreenInfo, maxLines: 1),
      const SizedBox(height: 12),
      Text(
        "注意：本工具检测结果仅供参考，若您不理解以下操作，请提供截图给有经验的玩家！",
        style: TextStyle(color: Colors.red, fontSize: 16),
      ),
      const SizedBox(height: 24),
      ListView.builder(
        itemCount: model.checkResult!.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final item = model.checkResult![index];
          return makeResultItem(item, model);
        },
      ),
      const SizedBox(height: 64),
    ];
  }

  Widget makeRescueBanner(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showToast(context,
            "您即将前往由 深空治疗中心（QQ群号：536454632 ） 提供的游戏异常救援服务，主要解决游戏安装失败与频繁闪退，如游戏玩法问题，请勿加群。");
        launchUrlString(
            "https://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=-M4wEme_bCXbUGT4LFKLH0bAYTFt70Ad&authKey=vHVr0TNgRmKu%2BHwywoJV6EiLa7La2VX74Vkyixr05KA0H9TqB6qWlCdY%2B9jLQ4Ha&noverify=0&group_code=536454632");
      },
      child: Tilt(
        shadowConfig: const ShadowConfig(maxIntensity: .2),
        borderRadius: BorderRadius.circular(12),
        child: Container(
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/rescue.png", width: 24, height: 24),
                  const SizedBox(width: 12),
                  const Text("需要帮助？ 点击加群寻求免费人工支援！"),
                ],
              ),
            )),
      ),
    );
  }

  Widget makeResultItem(
      MapEntry<String, String> item, GameDoctorUIModel model) {
    final errorNames = {
      "unSupport_system":
          MapEntry("不支持的操作系统，游戏可能无法运行", "请升级您的系统 (${item.value})"),
      "no_live_path": MapEntry("安装目录缺少LIVE文件夹，可能导致安装失败",
          "点击修复为您创建 LIVE 文件夹，完成后重试安装。(${item.value})"),
      "nvme_PhysicalBytes": MapEntry("新型 NVME 设备，与 RSI 启动器暂不兼容，可能导致安装失败",
          "为注册表项添加 ForcedPhysicalSectorSizeInBytes 值 模拟旧设备。硬盘分区(${item.value})"),
      "eac_file_miss": const MapEntry("EasyAntiCheat 文件丢失",
          "未在 LIVE 文件夹找到 EasyAntiCheat 文件 或 文件不完整，请使用 RSI 启动器校验文件"),
      "eac_not_install": const MapEntry("EasyAntiCheat 未安装 或 未正常退出",
          "EasyAntiCheat 未安装，请点击修复为您一键安装。（在游戏正常启动并结束前，该问题会一直出现，若您因为其他原因游戏闪退，可忽略此条目）"),
      "cn_user_name":
          const MapEntry("中文用户名！", "中文用户名可能会导致游戏启动/安装错误！ 点击修复按钮查看修改教程！"),
      "cn_install_path": MapEntry("中文安装路径！",
          "中文安装路径！这可能会导致游戏 启动/安装 错误！（${item.value}），请在RSI启动器更换安装路径。"),
      "low_ram": MapEntry(
          "物理内存过低", "您至少需要 16GB 的物理内存（Memory）才可运行此游戏。（当前大小：${item.value}）"),
    };
    bool isCheckedError = errorNames.containsKey(item.key);

    if (isCheckedError) {
      return Container(
        decoration: BoxDecoration(
          color: FluentTheme.of(context).cardColor,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          title: Text(
            errorNames[item.key]?.key ?? "",
            style: const TextStyle(fontSize: 18),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  "修复建议： ${errorNames[item.key]?.value ?? "暂无解决方法，请截图反馈"}",
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(.7)),
                ),
              ],
            ),
          ),
          trailing: Button(
            onPressed: (errorNames[item.key]?.value == null || model.isFixing)
                ? null
                : () async {
                    await model.doFix(item);
                    model.isFixing = false;
                    model.notifyListeners();
                  },
            child: const Padding(
              padding: EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
              child: Text("修复"),
            ),
          ),
        ),
      );
    }

    final isSubTitleUrl = item.value.startsWith("https://");

    return Container(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          item.key,
          style: const TextStyle(fontSize: 18),
        ),
        subtitle: isSubTitleUrl
            ? null
            : Column(
                children: [
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(.7)),
                  ),
                ],
              ),
        trailing: isSubTitleUrl
            ? Button(
                onPressed: () {
                  launchUrlString(item.value);
                },
                child: const Padding(
                  padding:
                      EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                  child: Text("查看解决方案"),
                ),
              )
            : null,
      ),
    );
  }

  @override
  String getUITitle(BuildContext context, GameDoctorUIModel model) =>
      "一键诊断  >   ${model.scInstalledPath}";
}