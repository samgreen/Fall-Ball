//
//  NewsBannerView.swift
//  Fall Ball
//
//  Created by Wheezy Salem on 4/24/24.
//

import SwiftUI

struct NewsBannerView: View {
    @Environment(\.dismiss) private var dismiss
    @GestureState private var translation: CGFloat = 0
    @State var showBallMenu = false
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    var body: some View {
        ZStack{
            RandomGradientView()
                .ignoresSafeArea()
            RotatingSunView()
            VStack{
                Capsule()
                    .frame(maxWidth: 45, maxHeight: 9)
                    .padding(.top, 9)
                    .foregroundColor(.black)
                    .opacity(0.3)
                HStack{
                    Text("🥳 NEW BALLS! 🥳")
                        .customTextStroke(width: 1.8)
                        .italic()
                        .bold()
                        .font(.largeTitle)
                }
                Spacer()
                HStack(spacing: 15){
                    UnicornView()
                        .offset(y: 30)
                        .animatedOffset(speed: 1.2)
                    NinjaBallView()
                        .offset(y: 30)
                        .animatedOffset(speed: 1.5)
                    EarthBallView()
                        .offset(y: 30)
                        .animatedOffset(speed: 0.9)
                }
                .scaleEffect(2.1)
                .padding(.bottom, 160)
                Spacer()
                Button{
                    self.showBallMenu = true
                } label: {
                    Text("Shop New Balls 🛍️")
                        .customTextStroke(width: 1.5)
                        .italic()
                        .bold()
                        .font(.title3)
                        .padding(12)
                        .background(.yellow)
                        .cornerRadius(15)
                        .padding(.bottom)
                }
                .buttonStyle(.roundedAndShadow6)
            }
            .gesture(
                DragGesture().updating($translation) { value, state, _ in
                    state = value.translation.height
                    dismiss()
                }
            )
            .frame(height: idiom == .pad ? .infinity : 390)
        }
        .sheet(isPresented: self.$showBallMenu) {
            CharactersMenuView()
        }
    }
}

#Preview {
    NewsBannerView()
}
