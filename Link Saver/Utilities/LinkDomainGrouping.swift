//
//  LinkDomainGrouping.swift
//  Link Saver
//
//  Created by Codex on 2026/01/02.
//

import Foundation

struct LinkDomainGroup: Identifiable {
    let domain: String?
    let links: [Link]

    var id: String {
        domain ?? "__unknown__"
    }
}

extension Sequence where Element == Link {
    func groupedByDomain() -> [LinkDomainGroup] {
        let grouped = Dictionary(grouping: self) { link in
            guard let domain = link.domain?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !domain.isEmpty
            else {
                return nil as String?
            }
            return domain.lowercased()
        }

        return grouped
            .map { LinkDomainGroup(domain: $0.key, links: $0.value) }
            .sorted { lhs, rhs in
                switch (lhs.domain, rhs.domain) {
                case let (lhsDomain?, rhsDomain?):
                    return lhsDomain < rhsDomain
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.links.count > rhs.links.count
                }
            }
    }
}

