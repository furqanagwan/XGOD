import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isoFileNames: [String] = []
    @State private var selectedFiles: [URL] = []
    @State private var destinationDirectory = ""
    @State private var progress: Double = 0.0
    @State private var isConverting: Bool = false

    var isConvertButtonDisabled: Bool {
        return isoFileNames.isEmpty || destinationDirectory.isEmpty || isConverting
    }

    var body: some View {
        VStack {
            ISOSelectionView(isoFileNames: $isoFileNames, selectedFiles: $selectedFiles, isConverting: $isConverting)
            DestinationSelectionView(destinationDirectory: $destinationDirectory, isConverting: $isConverting)
            ConvertButtonView(isConverting: $isConverting, isoFileNames: $isoFileNames, selectedFiles: $selectedFiles, destinationDirectory: $destinationDirectory, progress: $progress)
                .disabled(isConvertButtonDisabled)
            if isConverting {
                ProgressView(value: progress)
                Text("\(Int(progress * 100))% completed")
            }
        }
        .padding()
    }
}

struct ISOSelectionView: View {
    @Binding var isoFileNames: [String]
    @Binding var selectedFiles: [URL]
    @Binding var isConverting: Bool

    var body: some View {
        VStack {
            Button {
                selectISOFile()
            } label: {
                Text("XBOX 360 ISO'S")
            }
            .disabled(isConverting)
            List {
                ForEach(isoFileNames.indices, id: \.self) { index in
                    HStack {
                        Text(isoFileNames[index])
                        Spacer()
                        Button(action: {
                            removeISOFile(index: index)
                        }) {
                            Image(systemName: "trash")
                        }
                        .disabled(isConverting)
                    }
                }
            }
        }
    }

    func selectISOFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [UTType(filenameExtension: "iso")!]

        openPanel.begin { (result) in
            if result == NSApplication.ModalResponse.OK {
                let uniqueFiles = openPanel.urls.filter { !selectedFiles.contains($0) }
                self.selectedFiles += uniqueFiles
                self.isoFileNames += uniqueFiles.map { $0.lastPathComponent }
            }
        }
    }

    func removeISOFile(index: Int) {
        self.isoFileNames.remove(at: index)
        self.selectedFiles.remove(at: index)
    }
}

struct DestinationSelectionView: View {
    @Binding var destinationDirectory: String
    @Binding var isConverting: Bool

    var body: some View {
        VStack {
            Button {
                selectDestinationDirectory()
            } label: {
                Text("DESTINATION")
            }
            .disabled(isConverting)
            Text(destinationDirectory)
        }
    }

    func selectDestinationDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false

        openPanel.begin { (result) in
            if result == NSApplication.ModalResponse.OK {
                self.destinationDirectory = openPanel.url?.path ?? "No directory selected"
            }
        }
    }
}

struct ConvertButtonView: View {
    @Binding var isConverting: Bool
    @Binding var isoFileNames: [String]
    @Binding var selectedFiles: [URL]
    @Binding var destinationDirectory: String
    @Binding var progress: Double

    var body: some View {
        Button {
            convertISOFiles()
        } label: {
            Text("CONVERT")
        }
    }

    func convertISOFiles() {
        guard !selectedFiles.isEmpty else {
            print("No ISO file selected")
            return
        }

        self.isConverting = true

        let totalFiles = Double(selectedFiles.count)
        var completedFiles = 0.0

        for selectedFile in selectedFiles {
            let isoFilePath = selectedFile.path

            let process = Process()
            process.executableURL = Bundle.main.url(forResource: "iso2god-macos", withExtension: "")!
            process.arguments = [isoFilePath, destinationDirectory]

            do {
                try process.run()
            } catch {
                print("Failed to run the binary: \(error)")
            }

            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if process.isRunning {
                    self.progress = completedFiles / totalFiles
                } else {
                    completedFiles += 1.0
                    self.progress = completedFiles / totalFiles

                    if self.progress >= 1.0 {
                        self.isConverting = false
                        timer.invalidate()

                        // Resetting variables after conversion
                        self.isoFileNames = []
                        self.selectedFiles = []
                        self.destinationDirectory = ""
                        self.progress = 0.0 // Reset progress
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

