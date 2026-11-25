// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import ArgumentParser

@main
struct Gateway: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gateway",
        abstract: "The Harbor public REST API",
        subcommands: [
            Serve.self
        ],
        defaultSubcommand: Serve.self
    )
}
