//
//  ApplicationScanner.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation
import AppKit

/// 应用扫描器 Actor
actor ApplicationScanner: ApplicationScannerProtocol {
    
    // MARK: - Properties
    
    private var applications: [String: ApplicationInfo] = [:]
    private var isMonitoring = false
    private var fileSystemEventStream: FSEventStreamRef?
    
    var onApplicationsChanged: (@Sendable (Set<ApplicationChange>) -> Void)?
    
    /// 应用目录路径
    private let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "\(NSHomeDirectory())/Applications"),
        URL(fileURLWithPath: "/System/Applications")
    ]
    
    // MARK: - Public Methods
    
    /// 扫描所有应用程序
    func scanApplications() async -> [ApplicationInfo] {
        var allApps: [String: ApplicationInfo] = [:]
        
        for directory in applicationDirectories {
            let apps = await scanDirectory(directory)
            for app in apps {
                allApps[app.bundleIdentifier] = app
            }
        }
        
        applications = allApps
        return Array(allApps.values)
    }
    
    /// 启动文件系统监控
    func startMonitoring() async {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        await setupFileSystemMonitoring()
    }
    
    /// 停止文件系统监控
    func stopMonitoring() async {
        guard isMonitoring else { return }
        
        isMonitoring = false
        if let stream = fileSystemEventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            fileSystemEventStream = nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 扫描单个目录
    private func scanDirectory(_ directory: URL) async -> [ApplicationInfo] {
        var apps: [ApplicationInfo] = []
        
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return apps
        }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "app" else { continue }
            
            if let appInfo = await createApplicationInfo(from: fileURL) {
                apps.append(appInfo)
            }
            
            // 不递归进入 .app 包内部
            enumerator.skipDescendants()
        }
        
        return apps
    }
    
    /// 创建应用信息
    private func createApplicationInfo(from url: URL) async -> ApplicationInfo? {
        let bundle = Bundle(url: url)
        guard let bundle = bundle,
              let bundleIdentifier = bundle.bundleIdentifier,
              let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
                         bundle.object(forInfoDictionaryKey: "CFBundleName") as? String else {
            return nil
        }
        
        // 检查是否为系统应用
        let isSystemApp = url.path.hasPrefix("/System/") ||
                          url.path.hasPrefix("/System/Applications/")
        
        // 获取本地化名称
        let localizedName = createLocalizedName(from: bundle, defaultName: name)
        
        return ApplicationInfo(
            id: bundleIdentifier,
            name: name,
            bundleIdentifier: bundleIdentifier,
            bundleURL: url,
            iconURL: bundle.url(forResource: "AppIcon", withExtension: "icns"),
            isSystemApp: isSystemApp,
            installDate: (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date) ?? Date(),
            lastLaunchDate: nil,
            launchCount: 0,
            localizedName: localizedName
        )
    }
    
    /// 创建本地化名称
    private func createLocalizedName(from bundle: Bundle, defaultName: String) -> ApplicationInfo.LocalizedString {
        let localizations = bundle.localizations
        var english = defaultName
        var chineseSimplified: String?
        var chineseTraditional: String?
        var japanese: String?
        var korean: String?

        func localizedValue(for key: String, localization: String) -> String? {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            return (value != key && !value.isEmpty) ? value : nil
        }

        // 英文名优先 CFBundleDisplayName, fallback CFBundleName
        english = localizedValue(for: "CFBundleDisplayName", localization: "en") ?? localizedValue(for: "CFBundleName", localization: "en") ?? defaultName

        for localization in localizations {
            switch localization {
            case "zh-Hans", "zh_CN":
                chineseSimplified = localizedValue(for: "CFBundleDisplayName", localization: localization) ?? localizedValue(for: "CFBundleName", localization: localization)
            case "zh-Hant", "zh_TW":
                chineseTraditional = localizedValue(for: "CFBundleDisplayName", localization: localization) ?? localizedValue(for: "CFBundleName", localization: localization)
            case "ja":
                japanese = localizedValue(for: "CFBundleDisplayName", localization: localization) ?? localizedValue(for: "CFBundleName", localization: localization)
            case "ko":
                korean = localizedValue(for: "CFBundleDisplayName", localization: localization) ?? localizedValue(for: "CFBundleName", localization: localization)
            default:
                break
            }
        }

        return ApplicationInfo.LocalizedString(
            english: english,
            chineseSimplified: chineseSimplified,
            chineseTraditional: chineseTraditional,
            japanese: japanese,
            korean: korean
        )
    }
    
    /// 设置文件系统监控
    private func setupFileSystemMonitoring() async {
        let paths = applicationDirectories.map { $0.path } as CFArray
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                // 文件系统变更回调
                Task {
                    let scanner = Unmanaged<ApplicationScanner>.fromOpaque(clientCallBackInfo!).takeUnretainedValue()
                    await scanner.handleFileSystemChange()
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagIgnoreSelf)
        ) else {
            return
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        FSEventStreamStart(stream)
        
        fileSystemEventStream = stream
    }
    
    /// 处理文件系统变更
    private func handleFileSystemChange() async {
        let oldApps = applications
        let newApps = await scanApplications()
        
        var changes: Set<ApplicationChange> = []
        
        // 检测新增
        for app in newApps {
            if oldApps[app.bundleIdentifier] == nil {
                changes.insert(.added(app.bundleIdentifier))
            }
        }
        
        // 检测删除
        for (bundleId, _) in oldApps {
            if !newApps.contains(where: { $0.bundleIdentifier == bundleId }) {
                changes.insert(.removed(bundleId))
            }
        }
        
        if !changes.isEmpty {
            onApplicationsChanged?(changes)
        }
    }
}
