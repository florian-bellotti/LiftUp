import SwiftUI

/// Vue du timer de repos en plein écran - Style iOS 26
struct TimerView: View {
    @ObservedObject var timerViewModel: TimerViewModel
    let sessionColor: Color
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.appBackground
                .ignoresSafeArea()

            // Gradient subtil
            LinearGradient(
                colors: [
                    sessionColor.opacity(0.08),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Timer principal
                timerCircle

                // Status
                statusSection

                Spacer()

                // Controls
                controlsSection
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut(duration: 0.3), value: timerViewModel.isFinished)
        .animation(.easeInOut(duration: 0.3), value: timerViewModel.isPaused)
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.cardSurface)
                .frame(width: 260, height: 260)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)

            // Progress ring background
            Circle()
                .stroke(sessionColor.opacity(0.12), lineWidth: 12)
                .frame(width: 230, height: 230)

            // Progress ring
            Circle()
                .trim(from: 0, to: timerViewModel.progress)
                .stroke(
                    timerViewModel.isFinished ? Color.success : sessionColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 230, height: 230)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerViewModel.remainingSeconds)

            // Time display
            VStack(spacing: 4) {
                Text(timerViewModel.displayTime)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                if timerViewModel.remainingSeconds <= 10 && timerViewModel.remainingSeconds > 0 {
                    Text("PRÊT ?")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(sessionColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        if timerViewModel.isFinished {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.success)
                    .symbolEffect(.bounce)

                Text("Repos terminé !")
                    .font(.title3.weight(.semibold))

                Text("C'est reparti !")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .transition(.scale.combined(with: .opacity))
        } else if timerViewModel.isPaused {
            iOS26Badge(text: "EN PAUSE", color: .warning)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(spacing: 20) {
            // Adjust time buttons
            if timerViewModel.isRunning && !timerViewModel.isFinished {
                HStack(spacing: 12) {
                    adjustButton("-30s") { timerViewModel.addTime(-30) }
                    adjustButton("-15s") { timerViewModel.addTime(-15) }
                    adjustButton("+15s") { timerViewModel.addTime(15) }
                    adjustButton("+30s") { timerViewModel.addTime(30) }
                }
            }

            // Main controls
            HStack(spacing: 24) {
                // Stop button
                Button {
                    timerViewModel.stop()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .background(Color.cardSurface)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }

                // Play/Pause button
                if timerViewModel.isRunning && !timerViewModel.isFinished {
                    Button {
                        if timerViewModel.isPaused {
                            timerViewModel.resume()
                        } else {
                            timerViewModel.pause()
                        }
                    } label: {
                        Image(systemName: timerViewModel.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(sessionColor)
                            .clipShape(Circle())
                            .shadow(color: sessionColor.opacity(0.3), radius: 12, x: 0, y: 4)
                    }
                }

                // Reset/Continue button
                Button {
                    if timerViewModel.isFinished {
                        onDismiss()
                    } else {
                        timerViewModel.reset()
                    }
                } label: {
                    Image(systemName: timerViewModel.isFinished ? "checkmark" : "arrow.counterclockwise")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(timerViewModel.isFinished ? .white : .primary)
                        .frame(width: 56, height: 56)
                        .background(timerViewModel.isFinished ? Color.success : Color.cardSurface)
                        .clipShape(Circle())
                        .shadow(color: timerViewModel.isFinished ? Color.success.opacity(0.3) : .black.opacity(0.06), radius: timerViewModel.isFinished ? 12 : 8, x: 0, y: timerViewModel.isFinished ? 4 : 2)
                }
            }
        }
    }

    private func adjustButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.cardSurface)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

/// Mini timer à afficher en overlay - Style iOS 26
struct MiniTimerView: View {
    @ObservedObject var timerViewModel: TimerViewModel
    let sessionColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Mini progress ring
                ProgressRing(
                    progress: timerViewModel.progress,
                    color: timerViewModel.isFinished ? .success : sessionColor,
                    lineWidth: 3,
                    size: 32
                )
                .overlay {
                    if timerViewModel.isFinished {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.success)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(timerViewModel.displayTime)
                        .font(.subheadline.weight(.semibold).monospacedDigit())

                    Text(timerViewModel.isFinished ? "Terminé" : "Repos")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !timerViewModel.isFinished {
                    Image(systemName: timerViewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.cardSurface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Full Timer") {
    TimerView(
        timerViewModel: {
            let vm = TimerViewModel()
            vm.start(seconds: 120)
            return vm
        }(),
        sessionColor: .blue,
        onDismiss: {}
    )
}

#Preview("Mini Timer") {
    MiniTimerView(
        timerViewModel: {
            let vm = TimerViewModel()
            vm.start(seconds: 90)
            return vm
        }(),
        sessionColor: .blue,
        onTap: {}
    )
    .padding()
    .background(Color.appBackground)
}
