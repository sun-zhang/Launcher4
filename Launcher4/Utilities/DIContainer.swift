//
//  DIContainer.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 依赖注入容器
final class DIContainer: @unchecked Sendable {
    static let shared = DIContainer()
    
    private var registrations: [String: Registration] = [:]
    private var singletons: [String: Any] = [:]
    private let lock = NSLock()
    
    /// 注册作用域
    enum Scope {
        case singleton
        case transient
        case scoped(String)
    }
    
    /// 注册信息
    private struct Registration {
        let scope: Scope
        let factory: (DIContainer) -> Any
    }
    
    private init() {}
    
    // MARK: - Registration Methods
    
    /// 注册工厂方法
    func register<T>(_ type: T.Type, scope: Scope = .transient, factory: @escaping (DIContainer) -> T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        registrations[key] = Registration(scope: scope, factory: factory)
    }
    
    /// 注册单例实例
    func register<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        registrations[key] = Registration(scope: .singleton, factory: { _ in instance })
        singletons[key] = instance
    }
    
    // MARK: - Resolution Methods
    
    /// 解析依赖
    func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        // 检查单例缓存
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // 获取注册信息
        guard let registration = registrations[key] else {
            fatalError("Dependency '\(key)' not registered")
        }
        
        // 根据作用域创建实例
        let instance = registration.factory(self) as! T
        
        switch registration.scope {
        case .singleton:
            singletons[key] = instance
        case .transient:
            break
        case .scoped(let scopeId):
            // 作用域实例存储在单例字典中，带有作用域前缀
            let scopedKey = "\(scopeId).\(key)"
            if let scopedInstance = singletons[scopedKey] as? T {
                return scopedInstance
            }
            singletons[scopedKey] = instance
        }
        
        return instance
    }
    
    /// 解析可选依赖
    func resolveOptional<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        guard let registration = registrations[key] else {
            return nil
        }
        
        return registration.factory(self) as? T
    }
    
    // MARK: - Lifecycle Management
    
    /// 重置容器
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        
        registrations.removeAll()
        singletons.removeAll()
    }
    
    /// 移除特定类型的注册
    func remove<T>(_ type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        registrations.removeValue(forKey: key)
        singletons.removeValue(forKey: key)
    }
    
    /// 检查类型是否已注册
    func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        return registrations[key] != nil
    }
}

// MARK: - Convenience Extensions

extension DIContainer {
    /// 注册并返回自身以支持链式调用
    @discardableResult
    func registerSingleton<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) -> DIContainer {
        register(type, scope: .singleton, factory: factory)
        return self
    }
    
    @discardableResult
    func registerTransient<T>(_ type: T.Type, factory: @escaping (DIContainer) -> T) -> DIContainer {
        register(type, scope: .transient, factory: factory)
        return self
    }
}
