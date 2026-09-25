import Foundation
import AppKit
import SwiftUI

@Observable
class BuildViewModel {

    var imageName   = ""
    var contextPath = ""
    var buildOutput = ""
    var isBuilding  = false
    var formError: String?
    var buildSuccess = false

    private let buildService = DockerBuildService()
    
    private static let maxDisplayedOutputLength = 8_000

    @MainActor
    func selectDirectory() {
        NSApp.activate(ignoringOtherApps: true)

        let panel                     = NSOpenPanel()
        panel.canChooseFiles          = false
        panel.canChooseDirectories    = true
        panel.allowsMultipleSelection = false
        panel.prompt                  = "Select"
        panel.message                 = "Select the folder containing your Dockerfile"
        panel.level                   = .modalPanel

        if panel.runModal() == .OK, let url = panel.url {
            contextPath = url.path
            formError   = nil
        }
    }

    @MainActor
    func build() async {
        guard !imageName.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) {
                formError = "Image name is required"
            }
            return
        }

        guard !contextPath.isEmpty else {
            withAnimation(.easeOut(duration: 0.2)) {
                formError = "Select a project directory first"
            }
            return
        }

        guard buildService.dockerfileExists(at: contextPath) else {
            withAnimation(.easeOut(duration: 0.2)) {
                formError = "No Dockerfile found in the selected directory"
            }
            return
        }

        withAnimation(.easeOut(duration: 0.2)) { formError = nil }
        isBuilding   = true
        buildOutput  = ""
        buildSuccess = false

        do {
            try await Task.detached(priority: .userInitiated) {
                try await self.buildService.build(
                    imageName: self.imageName,
                    contextPath: self.contextPath
                ) { output in
                    self.buildOutput += output
                    if self.buildOutput.count > Self.maxDisplayedOutputLength {
                        self.buildOutput = String(self.buildOutput.suffix(Self.maxDisplayedOutputLength))
                    }
                }
            }.value
            isBuilding   = false
            buildSuccess = true
        } catch {
            isBuilding = false
            withAnimation(.easeOut(duration: 0.2)) {
                formError = error.localizedDescription
            }
        }
    }

    func reset() {
        imageName    = ""
        contextPath  = ""
        buildOutput  = ""
        formError    = nil
        buildSuccess = false
    }
}
