//
//  GridSize.swift
//  Launcher4
//
//  Created by Sisyphus on 2026/2/21.
//

import Foundation

/// 网格尺寸
struct GridSize: Codable, Equatable, Hashable, Sendable {
    let columns: Int
    let rows: Int
    
    /// 默认网格尺寸 (7列 x 5行)
    static let `default` = GridSize(columns: 7, rows: 5)
    
    /// 每页项目数量
    var itemsPerPage: Int {
        columns * rows
    }
    
    /// 计算需要的页数
    func pageCount(for totalItems: Int) -> Int {
        guard totalItems > 0 else { return 1 }
        return (totalItems + itemsPerPage - 1) / itemsPerPage
    }
    
    /// 验证尺寸是否有效
    var isValid: Bool {
        columns >= 3 && columns <= 12 && rows >= 3 && rows <= 10
    }
}
