import SwiftUI

/// Экран финальных результатов игры
struct ResultsView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Заголовок
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.hatGold)
                Text("Игра окончена!")
                    .font(.title)
                    .fontWeight(.bold)
            }

            // Победитель
            if let winner = viewModel.engine.winner {
                VStack(spacing: 4) {
                    Text("Победитель:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(winner.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("\(winner.score) очков")
                        .font(.headline)
                }
            }

            // Таблица результатов
            VStack(spacing: 12) {
                Text("Результаты")
                    .font(.headline)

                ForEach(Array(viewModel.standings.enumerated()), id: \.element.id) { index, team in
                    HStack {
                        Text("\(index + 1).")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 30)
                        Text(team.name)
                            .font(.body)
                        Spacer()
                        Text("\(team.score)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(index == 0 ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Кнопки
            VStack(spacing: 12) {
                Button {
                    viewModel.playAgain()
                } label: {
                    Text("Играть ещё раз")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    viewModel.goHome()
                } label: {
                    Text("На главную")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ResultsView(viewModel: GameViewModel())
}
