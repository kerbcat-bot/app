// ignore_for_file: avoid_build_context_in_providers
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:starcitizen_doctor/api/analytics.dart';
import 'package:starcitizen_doctor/api/api.dart';
import 'package:starcitizen_doctor/common/helper/log_helper.dart';
import 'package:starcitizen_doctor/common/helper/system_helper.dart';
import 'package:starcitizen_doctor/common/io/rs_http.dart';
import 'package:starcitizen_doctor/common/utils/log.dart';
import 'package:starcitizen_doctor/common/utils/provider.dart';
import 'package:starcitizen_doctor/provider/aria2c.dart';
import 'package:starcitizen_doctor/ui/home/downloader/home_downloader_ui_model.dart';
import 'package:starcitizen_doctor/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:xml/xml.dart';

import 'dialogs/hosts_booster_dialog_ui.dart';

part 'tools_ui_model.g.dart';

part 'tools_ui_model.freezed.dart';

class ToolsItemData {
  String key;

  ToolsItemData(this.key, this.name, this.infoString, this.icon, {this.onTap});

  String name;
  String infoString;
  Widget icon;
  AsyncCallback? onTap;
}

@freezed
class ToolsUIState with _$ToolsUIState {
  factory ToolsUIState({
    @Default(false) bool working,
    @Default("") String scInstalledPath,
    @Default("") String rsiLauncherInstalledPath,
    @Default([]) List<String> scInstallPaths,
    @Default([]) List<String> rsiLauncherInstallPaths,
    @Default([]) List<ToolsItemData> items,
    @Default(false) bool isItemLoading,
  }) = _ToolsUIState;
}

@riverpod
class ToolsUIModel extends _$ToolsUIModel {
  @override
  ToolsUIState build() {
    state = ToolsUIState();
    return state;
  }

  loadToolsCard(BuildContext context, {bool skipPathScan = false}) async {
    if (state.isItemLoading) return;
    var items = <ToolsItemData>[];
    state = state.copyWith(items: items, isItemLoading: true);
    if (!skipPathScan) {
      await reScanPath(context);
    }
    try {
      items = [
        ToolsItemData(
          "systemnfo",
          S.current.tools_action_view_system_info,
          S.current.tools_action_info_view_critical_system_info,
          const Icon(FluentIcons.system, size: 24),
          onTap: () => _showSystemInfo(context),
        ),
        ToolsItemData(
          "p4k_downloader",
          S.current.tools_action_p4k_download_repair,
          S.current.tools_action_info_p4k_download_repair_tip,
          const Icon(FontAwesomeIcons.download, size: 24),
          onTap: () => _downloadP4k(context),
        ),
        ToolsItemData(
          "hosts_booster",
          S.current.tools_action_hosts_acceleration_experimental,
          S.current.tools_action_info_hosts_acceleration_experimental_tip,
          const Icon(FluentIcons.virtual_network, size: 24),
          onTap: () => _doHostsBooster(context),
        ),
        ToolsItemData(
          "reinstall_eac",
          S.current.tools_action_reinstall_easyanticheat,
          S.current.tools_action_info_reinstall_eac,
          const Icon(FluentIcons.game, size: 24),
          onTap: () => _reinstallEAC(context),
        ),
        ToolsItemData(
          "rsilauncher_admin_mode",
          S.current.tools_action_rsi_launcher_admin_mode,
          S.current.tools_action_info_run_rsi_as_admin,
          const Icon(FluentIcons.admin, size: 24),
          onTap: () => _adminRSILauncher(context),
        ),
      ];

      state = state.copyWith(items: items);
      if (!context.mounted) return;
      items.add(await _addShaderCard(context));
      state = state.copyWith(items: items);
      if (!context.mounted) return;
      items.add(await _addPhotographyCard(context));
      state = state.copyWith(items: items);
      if (!context.mounted) return;
      items.addAll(await _addLogCard(context));
      state = state.copyWith(items: items);
      if (!context.mounted) return;
      items.addAll(await _addNvmePatchCard(context));
      state = state.copyWith(items: items, isItemLoading: false);
    } catch (e) {
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_init_failed(e));
    }
  }

  Future<List<ToolsItemData>> _addLogCard(BuildContext context) async {
    double logPathLen = 0;
    try {
      logPathLen =
          (await File(await SCLoggerHelper.getLogFilePath() ?? "").length()) /
              1024 /
              1024;
    } catch (_) {}
    return [
      ToolsItemData(
        "rsilauncher_log_fix",
        S.current.tools_action_rsi_launcher_log_fix,
        S.current.tools_action_info_rsi_launcher_log_issue(
            logPathLen.toStringAsFixed(4)),
        const Icon(FontAwesomeIcons.bookBible, size: 24),
        onTap: () => _rsiLogFix(context),
      ),
    ];
  }

  Future<List<ToolsItemData>> _addNvmePatchCard(BuildContext context) async {
    final nvmePatchStatus = await SystemHelper.checkNvmePatchStatus();
    return [
      if (nvmePatchStatus)
        ToolsItemData(
          "remove_nvme_settings",
          S.current.tools_action_remove_nvme_registry_patch,
          S.current.tools_action_info_nvme_patch_issue(nvmePatchStatus
              ? S.current.localization_info_installed
              : S.current.tools_action_info_not_installed),
          const Icon(FluentIcons.hard_drive, size: 24),
          onTap: nvmePatchStatus
              ? () async {
                  state = state.copyWith(working: true);
                  await SystemHelper.doRemoveNvmePath();
                  state = state.copyWith(working: false);
                  if (!context.mounted) return;
                  showToast(context,
                      S.current.tools_action_info_removed_restart_effective);
                  loadToolsCard(context, skipPathScan: true);
                }
              : null,
        ),
      if (!nvmePatchStatus)
        ToolsItemData(
          "add_nvme_settings",
          S.current.tools_action_write_nvme_registry_patch,
          S.current.tools_action_info_manual_nvme_patch,
          const Icon(FontAwesomeIcons.cashRegister, size: 24),
          onTap: () async {
            state = state.copyWith(working: true);
            final r = await SystemHelper.addNvmePatch();
            if (r == "") {
              if (!context.mounted) return;
              showToast(
                  context, S.current.tools_action_info_fix_success_restart);
            } else {
              if (!context.mounted) return;
              showToast(context, S.current.doctor_action_result_fix_fail(r));
            }
            state = state.copyWith(working: false);
            loadToolsCard(context, skipPathScan: true);
          },
        )
    ];
  }

  Future<ToolsItemData> _addShaderCard(BuildContext context) async {
    final gameShaderCachePath = await SCLoggerHelper.getShaderCachePath();
    final shaderSize = ((await SystemHelper.getDirLen(gameShaderCachePath ?? "",
                skipPath: ["$gameShaderCachePath\\Crashes"])) /
            1024 /
            1024)
        .toStringAsFixed(4);
    return ToolsItemData(
      "clean_shaders",
      S.current.tools_action_clear_shader_cache,
      S.current.tools_action_info_shader_cache_issue(shaderSize),
      const Icon(FontAwesomeIcons.shapes, size: 24),
      onTap: () => _cleanShaderCache(context),
    );
  }

  Future<ToolsItemData> _addPhotographyCard(BuildContext context) async {
    // 获取配置文件状态
    final isEnable = await _checkPhotographyStatus(context);

    return ToolsItemData(
      "photography_mode",
      isEnable
          ? S.current.tools_action_close_photography_mode
          : S.current.tools_action_open_photography_mode,
      isEnable
          ? S.current.tools_action_info_restore_lens_shake
          : S.current.tools_action_info_one_key_close_lens_shake,
      const Icon(FontAwesomeIcons.camera, size: 24),
      onTap: () => _onChangePhotographyMode(context, isEnable),
    );
  }

  /// ---------------------------- func -------------------------------------------------------
  /// -----------------------------------------------------------------------------------------
  /// -----------------------------------------------------------------------------------------
  /// -----------------------------------------------------------------------------------------

  Future<void> reScanPath(BuildContext context) async {
    var scInstallPaths = <String>[];
    var rsiLauncherInstallPaths = <String>[];
    var scInstalledPath = "";
    var rsiLauncherInstalledPath = "";

    state = state.copyWith(
      scInstalledPath: scInstalledPath,
      rsiLauncherInstalledPath: rsiLauncherInstalledPath,
      scInstallPaths: scInstallPaths,
      rsiLauncherInstallPaths: rsiLauncherInstallPaths,
    );

    try {
      rsiLauncherInstalledPath = await SystemHelper.getRSILauncherPath();
      rsiLauncherInstallPaths.add(rsiLauncherInstalledPath);
      final listData = await SCLoggerHelper.getLauncherLogList();
      if (listData == null) {
        return;
      }
      scInstallPaths = await SCLoggerHelper.getGameInstallPath(listData,
          checkExists: false, withVersion: ["LIVE", "PTU", "EPTU"]);
      if (scInstallPaths.isNotEmpty) {
        scInstalledPath = scInstallPaths.first;
      }
      state = state.copyWith(
        scInstalledPath: scInstalledPath,
        rsiLauncherInstalledPath: rsiLauncherInstalledPath,
        scInstallPaths: scInstallPaths,
        rsiLauncherInstallPaths: rsiLauncherInstallPaths,
      );
    } catch (e) {
      dPrint(e);
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_log_file_parse_failed);
    }

    if (rsiLauncherInstalledPath == "") {
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_rsi_launcher_not_found);
    }
    if (scInstalledPath == "") {
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_star_citizen_not_found);
    }
  }

  /// 重装EAC
  Future<void> _reinstallEAC(BuildContext context) async {
    if (state.scInstalledPath.isEmpty) {
      showToast(
          context, S.current.tools_action_info_valid_game_directory_needed);
      return;
    }
    state = state.copyWith(working: true);
    try {
      final eacPath = "${state.scInstalledPath}\\EasyAntiCheat";
      final eacJsonPath = "$eacPath\\Settings.json";
      if (await File(eacJsonPath).exists()) {
        Map<String, String> envVars = Platform.environment;
        final eacJsonData = await File(eacJsonPath).readAsString();
        final Map eacJson = json.decode(eacJsonData);
        final eacID = eacJson["productid"];
        if (eacID != null) {
          final eacCacheDir =
              Directory("${envVars["appdata"]}\\EasyAntiCheat\\$eacID");
          if (await eacCacheDir.exists()) {
            await eacCacheDir.delete(recursive: true);
          }
        }
      }
      final dir = Directory(eacPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      final eacLauncher =
          File("${state.scInstalledPath}\\StarCitizen_Launcher.exe");
      if (await eacLauncher.exists()) {
        await eacLauncher.delete(recursive: true);
      }
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_eac_file_removed);
      _adminRSILauncher(context);
    } catch (e) {
      showToast(context, S.current.tools_action_info_error_occurred(e));
    }
    state = state.copyWith(working: false);
    loadToolsCard(context, skipPathScan: true);
  }

  Future<String> getSystemInfo() async {
    return S.current.tools_action_info_system_info_content(
        await SystemHelper.getSystemName(),
        await SystemHelper.getCpuName(),
        await SystemHelper.getSystemMemorySizeGB(),
        await SystemHelper.getGpuInfo(),
        await SystemHelper.getDiskInfo());
  }

  /// 管理员模式运行 RSI 启动器
  Future _adminRSILauncher(BuildContext context) async {
    if (state.rsiLauncherInstalledPath == "") {
      showToast(context,
          S.current.tools_action_info_rsi_launcher_directory_not_found);
    }
    SystemHelper.checkAndLaunchRSILauncher(state.rsiLauncherInstalledPath);
  }

  Future<void> _rsiLogFix(BuildContext context) async {
    state = state.copyWith(working: true);
    final path = await SCLoggerHelper.getLogFilePath();
    if (!await File(path!).exists()) {
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_log_file_not_exist);
      return;
    }
    try {
      SystemHelper.killRSILauncher();
      await File(path).delete(recursive: true);
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_cleanup_complete);
      SystemHelper.checkAndLaunchRSILauncher(state.rsiLauncherInstalledPath);
    } catch (_) {
      if (!context.mounted) return;
      showToast(context, S.current.tools_action_info_cleanup_failed(path));
    }

    state = state.copyWith(working: false);
  }

  openDir(path) async {
    await Process.run(
        SystemHelper.powershellPath, ["explorer.exe", "/select,\"$path\""]);
  }

  Future _showSystemInfo(BuildContext context) async {
    state = state.copyWith(working: true);
    final systemInfo = await getSystemInfo();
    if (!context.mounted) return;
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(S.current.tools_action_info_system_info_title),
        content: Text(systemInfo),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .65,
        ),
        actions: [
          FilledButton(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 2, bottom: 2, left: 8, right: 8),
              child: Text(S.current.action_close),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    state = state.copyWith(working: false);
  }

  Future<void> _cleanShaderCache(BuildContext context) async {
    state = state.copyWith(working: true);
    final gameShaderCachePath = await SCLoggerHelper.getShaderCachePath();
    final l =
        await Directory(gameShaderCachePath!).list(recursive: false).toList();
    for (var value in l) {
      if (value is Directory) {
        if (!value.absolute.path.contains("Crashes")) {
          await value.delete(recursive: true);
        }
      }
    }
    if (!context.mounted) return;
    loadToolsCard(context, skipPathScan: true);
    state = state.copyWith(working: false);
  }

  Future<void> _downloadP4k(BuildContext context) async {
    String savePath = state.scInstalledPath;
    String fileName = "Data.p4k";

    if ((await SystemHelper.getPID("\"RSI Launcher\"")).isNotEmpty) {
      if (!context.mounted) return;
      showToast(
          context, S.current.tools_action_info_rsi_launcher_running_warning,
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .35));
      return;
    }

    if (!context.mounted) return;
    await showToast(context, S.current.tools_action_info_p4k_file_description);
    try {
      state = state.copyWith(working: true);
      final aria2cManager = ref.read(aria2cModelProvider.notifier);
      await aria2cManager
          .launchDaemon(appGlobalState.applicationBinaryModuleDir!);
      final aria2c = ref.read(aria2cModelProvider).aria2c!;

      // check download task list
      for (var value in [
        ...await aria2c.tellActive(),
        ...await aria2c.tellWaiting(0, 100000)
      ]) {
        final t = HomeDownloaderUIModel.getTaskTypeAndName(value);
        if (t.key == "torrent" && t.value.contains("Data.p4k")) {
          if (!context.mounted) return;
          showToast(
              context, S.current.tools_action_info_p4k_download_in_progress);
          state = state.copyWith(working: false);
          return;
        }
      }

      var torrentUrl = "";
      final l = await Api.getAppTorrentDataList();
      for (var torrent in l) {
        if (torrent.name == "Data.p4k") {
          torrentUrl = torrent.url!;
        }
      }
      if (torrentUrl == "") {
        state = state.copyWith(working: false);
        if (!context.mounted) return;
        showToast(
            context, S.current.tools_action_info_function_under_maintenance);
        return;
      }

      final userSelect = await FilePicker.platform.saveFile(
          initialDirectory: savePath,
          fileName: fileName,
          lockParentWindow: true);
      if (userSelect == null) {
        state = state.copyWith(working: false);
        return;
      }

      savePath = userSelect;
      dPrint(savePath);

      if (savePath.endsWith("\\$fileName")) {
        savePath = savePath.substring(0, savePath.length - fileName.length - 1);
      }

      if (!context.mounted) return;
      final btData = await RSHttp.get(torrentUrl).unwrap(context: context);
      if (btData == null || btData.data == null) {
        state = state.copyWith(working: false);
        return;
      }
      final b64Str = base64Encode(btData.data!);

      final gid =
          await aria2c.addTorrent(b64Str, extraParams: {"dir": savePath});
      state = state.copyWith(working: false);
      dPrint("Aria2cManager.aria2c.addUri resp === $gid");
      await aria2c.saveSession();
      AnalyticsApi.touch("p4k_download");
      if (!context.mounted) return;
      context.push("/index/downloader");
    } catch (e) {
      state = state.copyWith(working: false);
      if (!context.mounted) return;
      showToast(context, S.current.app_init_failed_with_reason(e));
    }
    await Future.delayed(const Duration(seconds: 3));
    launchUrlString(
        "https://citizenwiki.cn/SC%E6%B1%89%E5%8C%96%E7%9B%92%E5%AD%90#%E5%88%86%E6%B5%81%E4%B8%8B%E8%BD%BD%E6%95%99%E7%A8%8B");
  }

  Future<bool> _checkPhotographyStatus(BuildContext context,
      {bool? setMode}) async {
    final scInstalledPath = state.scInstalledPath;
    final keys = ["AudioShakeStrength", "CameraSpringMovement", "ShakeScale"];
    final attributesFile = File(
        "$scInstalledPath\\USER\\Client\\0\\Profiles\\default\\attributes.xml");
    if (setMode == null) {
      bool isEnable = false;
      if (scInstalledPath.isNotEmpty) {
        if (await attributesFile.exists()) {
          final xmlFile =
              XmlDocument.parse(await attributesFile.readAsString());
          isEnable = true;
          for (var k in keys) {
            if (!isEnable) break;
            final e = xmlFile.rootElement.children
                .where((element) => element.getAttribute("name") == k)
                .firstOrNull;
            if (e != null && e.getAttribute("value") == "0") {
            } else {
              isEnable = false;
            }
          }
        }
      }
      return isEnable;
    } else {
      if (!await attributesFile.exists()) {
        if (!context.mounted) return false;
        showToast(context, S.current.tools_action_info_config_file_not_exist);
        return false;
      }
      final xmlFile = XmlDocument.parse(await attributesFile.readAsString());
      // clear all
      xmlFile.rootElement.children.removeWhere(
          (element) => keys.contains(element.getAttribute("name")));
      if (setMode) {
        for (var element in keys) {
          XmlElement newNode = XmlElement(XmlName('Attr'), [
            XmlAttribute(XmlName('name'), element),
            XmlAttribute(XmlName('value'), '0'),
          ]);
          xmlFile.rootElement.children.add(newNode);
        }
      }
      dPrint(xmlFile);
      await attributesFile.delete();
      await attributesFile.writeAsString(xmlFile.toXmlString(pretty: true));
    }
    return true;
  }

  _onChangePhotographyMode(BuildContext context, bool isEnable) async {
    _checkPhotographyStatus(context, setMode: !isEnable)
        .unwrap(context: context);
    loadToolsCard(context, skipPathScan: true);
  }

  void onChangeGamePath(String v) {
    state = state.copyWith(scInstalledPath: v);
  }

  void onChangeLauncherPath(String s) {
    state = state.copyWith(rsiLauncherInstalledPath: s);
  }

  _doHostsBooster(BuildContext context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => const HostsBoosterDialogUI());
  }
}
