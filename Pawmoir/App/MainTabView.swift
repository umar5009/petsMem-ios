import SwiftUI

enum AppTab: Hashable {
    case diary
    case create
    case shop
    case pets
}

struct MainTabView: View {
    @State private var tab: AppTab = .diary
    @State private var showQuickAdd = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                DiaryHomeView(onQuickAdd: { showQuickAdd = true })
            }
            .tabItem { Label("Diary", systemImage: "book.closed") }
            .tag(AppTab.diary)
            .accessibilityIdentifier("tab.diary")

            NavigationStack {
                StudioHomeView()
            }
            .tabItem { Label("Create", systemImage: "sparkles") }
            .tag(AppTab.create)

            NavigationStack {
                ShopHomeView()
            }
            .tabItem { Label("Shop", systemImage: "bag") }
            .tag(AppTab.shop)

            NavigationStack {
                PetsHomeView()
            }
            .tabItem { Label("Pets", systemImage: "pawprint") }
            .tag(AppTab.pets)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                Haptics.tap()
                showQuickAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PawColor.onPrimary)
                    .frame(width: 56, height: 56)
                    .background(PawColor.primary, in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            }
            .accessibilityLabel("Add a memory")
            .accessibilityIdentifier("quickAdd")
            .padding(.trailing, 20)
            .padding(.bottom, 64)
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddView()
        }
    }
}
