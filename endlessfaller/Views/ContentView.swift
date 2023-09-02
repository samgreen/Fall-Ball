//
//  ContentView.swift
//  endlessfaller
//
//  Created by Wheezy Salem on 7/12/23.
//

import SwiftUI
import VTabView
import AudioToolbox
import CloudKit
import AVFoundation


let bestScoreKey = "BestScore"
let levels = 1000
let difficulty = 100

struct ContentView: View {
    
    let deviceHeight = UIScreen.main.bounds.height
    let deviceWidth = UIScreen.main.bounds.width
    @AppStorage(bestScoreKey) var bestScore: Int = UserDefaults.standard.integer(forKey: bestScoreKey)
    @StateObject var appModel = AppModel()
    @StateObject private var CKVM = CloudKitCrud()
    @State var score: Int = 0
    @State var highestScoreInGame: Int = -1
    @State var currentScore: Int = 0
    @State var currentIndex: Int = -1
    @State var speed: Double = 2
    @State var isAnimating = false
    @State var gameOver = false
    @State var freezeScrolling = false
    @State var showCharactersMenu = false
    @State var showLeaderBoard = false
    @State var showNewBestScore = false
    @State var gameShouldBeOver = false
    @State var showWastedScreen = false
    @State var levelYPosition: CGFloat = 0
    @State var playedCharacter = ""
    @State var musicPlayer: AVAudioPlayer!
    @State var punchSoundEffect: AVAudioPlayer!
    @State var placeOnLeaderBoard = 0
    @State var recordID: CKRecord.ID? = nil
    @State var colors: [Color] = (1...levels).map { _ in
        Color(red: .random(in: 0.3...1), green: .random(in: 0.3...1), blue: .random(in: 0.3...1))
    }
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    func dropCircle() {
        withAnimation(
            Animation.linear(duration: speed)
        ) {
            isAnimating = true
        }
    }
    
    func gameOverOperations() {
        self.punchSoundEffect.play()
        showNewBestScore = false
        gameOver = true
        currentScore = highestScoreInGame
        if currentScore > bestScore {
            bestScore = currentScore
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
        freezeScrolling = true
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
        showWastedScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.colors = (1...levels).map { _ in
                Color(red: .random(in: 0.3...1), green: .random(in: 0.3...1), blue: .random(in: 0.3...1))
            }
            freezeScrolling = false
        }
        gameShouldBeOver = false
        self.playedCharacter = appModel.selectedCharacter
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            showWastedScreen = false
            self.currentIndex = -1
            highestScoreInGame = -1
            timer.invalidate() // Stop the timer after the reset
        }
        CKVM.updateRecord(newScore: bestScore, newCharacterID: appModel.selectedCharacter)
    }
    
    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        ScrollView {
            ZStack{
                VTabView(selection: $currentIndex) {
                    let character = appModel.characters.first(where: { $0.characterID == appModel.selectedCharacter})
                    VStack{
                        Spacer()
                        if !gameOver {
                            VStack{
                                Text("Swipe up \nto play")
                                    .bold()
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .padding()
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.green)
                            }
                            .font(.largeTitle)
                            .scaleEffect(1.5)
                            .flashing()
                            .tag(-1)
                            .offset(y: deviceHeight * 0.06)
                        } else {
                            VStack{
                                Text("Game Over!")
                                    .underline(color: .red)
                                    .italic()
                                    .bold()
                                    .font(.largeTitle)
                                    .scaleEffect(1.6)
                                    .padding(.bottom, 20)
//                                if CKVM.scores.isEmpty{
//                                    ProgressView()
//                                } else {
//                                    HStack{
//                                        Text("🌍 #\(self.placeOnLeaderBoard) on Board")
//                                            .italic()
//                                            .bold()
//                                            .font(.title)
//                                            .padding(.bottom, 6)
//                                        PodiumView()
//                                            .scaleEffect(0.6)
//                                            .offset(x: -6, y: -3)
//                                    }
//                                    .offset(x: 6)
//                                }
                                HStack{
                                    VStack{
                                        Text("Ball:")
                                            .font(.largeTitle)
                                            .bold()
                                            .italic()
                                        let character = appModel.characters.first(where: { $0.characterID == playedCharacter})
                                        AnyView(character!.character)
                                            .scaleEffect(2)
                                            .padding(.top)
                                    }
                                    .offset(y: -(deviceHeight * 0.02))
                                    .padding(.leading, deviceWidth * 0.12)
                                    Spacer()
                                        .frame(maxWidth: 75)
                                    VStack(alignment: .trailing){
                                        Spacer()
                                            .frame(maxHeight: 10)
                                        Text("Score:")
                                        //.foregroundColor(.blue)
                                            .bold()
                                            .italic()
                                        Text(String(currentScore))
                                            .bold()
                                            .offset(y: 6)
                                        Spacer()
                                            .frame(maxHeight: 18)
                                        Text("Best:")
                                        //.foregroundColor(.blue)
                                            .bold()
                                            .italic()
                                        Text(String(bestScore))
                                            .bold()
                                            .offset(y: 6)
                                        Spacer()
                                            .frame(maxHeight: 10)
                                    }
                                    .padding(.trailing, deviceWidth * 0.07)
                                    .padding()
                                    .font(.largeTitle)
                                }
                                .background{
                                    Rectangle()
                                        .foregroundColor(.primary.opacity(0.15))
                                        .cornerRadius(30)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 30)
                                                .stroke(Color.yellow, lineWidth: 3)
                                        )
                                        .padding(.horizontal,9)
                                }
                                VStack{
                                    Text("Swipe up to \nplay again")
                                        .bold()
                                        .italic()
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.green)
                                }
                                .foregroundColor(.primary)
                                .font(.largeTitle)
                                .scaleEffect(1.0)
                                .tag(-1)
                            }
                            .offset(y: deviceHeight * 0.1)
                        }
                        Spacer()
                        ZStack{
                            HStack{
                                Button {
                                    appModel.mute.toggle()
                                } label: {
                                    Image(systemName: appModel.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .foregroundColor(.teal)
                                        .font(.largeTitle)
                                        .scaleEffect(1.2)
                                        .padding(36)
                                }
                                .onChange(of: appModel.mute) { setting in
                                    if setting == true {
                                        self.musicPlayer.setVolume(0, fadeDuration: 0)
                                    } else {
                                        self.musicPlayer.setVolume(1, fadeDuration: 0)
                                    }
                                }
                                Spacer()
                                Button {
                                    showCharactersMenu = true
                                } label: {
                                    ZStack{
                                        AnyView(character!.character)
                                    }
                                    .padding(36)
                                }
                            }
                            Button {
                                showLeaderBoard = true
                            } label: {
                                PodiumView()
                                    .foregroundColor(.primary)
                                    .font(.largeTitle)
                                    .padding(36)
                            }
                        }
                    }
                    ForEach(colors.indices, id: \.self) { index in
                        ZStack{
                            colors[index]
                            if highestScoreInGame == index && !showWastedScreen {
                                GeometryReader { geometry in
                                    ZStack{
                                        if !gameShouldBeOver{
                                            VStack{
                                                LinearGradient(
                                                    colors: [.gray.opacity(0.01), .white],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            }
                                            .frame(width: 44, height: 45)
                                            .offset(x: 0, y:-23)
                                        }
                                        AnyView(character!.character)
                                    }
                                    .position(x: deviceWidth/2, y: isAnimating ? deviceHeight - 23 : -27)
                                    .onChange(of: geometry.frame(in: .global).minY) { newYPosition in
                                        levelYPosition = newYPosition
                                    }
                                }
                            }
                            if index == 0{
                                ZStack{
                                    Rectangle()
                                        .frame(width: 100, height: 80)
                                        .foregroundColor(.primary)
                                        .colorInvert()
                                    PodiumView()
                                        .foregroundColor(.primary)
                                        .font(.largeTitle)
                                        .offset(y: -20)
                                    
                                }
                                .position(x: deviceWidth/2, y: -40)
                                
                            }
                            if currentIndex == 0 && !gameOver {
                                KeepSwiping()
                            }
                            if currentIndex == 1 && !gameOver {
                                Instruction()
                            }
                        }
                    }
                }
                .frame(
                    width: deviceWidth,
                    height: deviceHeight
                )
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentIndex) { newValue in
                    if currentIndex != -1{
                        gameOver = false
                    }
                    gameShouldBeOver = false
                    score = newValue
                    if score > highestScoreInGame {
                        highestScoreInGame = score
                        if currentIndex < difficulty {
                            speed = 2.0 / ((Double(newValue) / 3) + 1)
                        }
                        isAnimating = false
                        dropCircle()
                    }
                    impactMed.impactOccurred()
                    if currentIndex > bestScore && currentIndex > 3 {
                        showNewBestScore = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
                        if currentIndex <= newValue && currentIndex != -1 {
                            gameShouldBeOver = true
                            if levelYPosition >= 0 {
                                gameOverOperations()
                            }
                        }
                    }
                }
                .onChange(of: levelYPosition) { yPosition in
                    if yPosition >= 0 && gameShouldBeOver {
                        gameOverOperations()
                    }
                }
                if currentIndex >= 0 {
                    VStack{
                        HStack{
                            Text(String(score))
                                .font(.system(size: 90))
                                .padding(36)
                                .padding(.top, 30)
                                .foregroundColor(.black)
                            Spacer()
//                            Text("\(self.speed)")
//                                .foregroundColor(.black)
//                                .padding()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                
                if showWastedScreen {
                    ZStack{
                        Color.red.opacity(0.5)
                            .strobing()
                        WastedView()
                    }
                } else{
                    if !showNewBestScore {
                        
                        if currentIndex > 21 && currentIndex < 33 {
                            KeepGoing()
                        }
                        
                        if currentIndex > 100 && currentIndex < 115 {
                            YourGood()
                        }
                        
                        if currentIndex > 200 && currentIndex < 215 {
                            YourInsane()
                        }
                        
                        if currentIndex > 300 && currentIndex < 315 {
                            GoBerzerk()
                        }
                        
                    } else {
                        CelebrationEffect()
                        NewBestScore()
                    }
                    if currentIndex > 315 {
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                BearView()
                            }
                        }
                    }
                    if currentIndex > 115 {
                        ReactionsView()
                            .offset(y: 70)
                    }
                    
                    if currentIndex > 215 {
                        VStack{
                            Spacer()
                            HStack{
                                SwiftUIXmasTree2()
                                    .scaleEffect(0.5)
                                    .offset(x:-deviceWidth/10)
                                Spacer()
                            }
                        }
                    }
                    
                    if currentIndex > 33 {
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                SVGCharacterView()
                                    .scaleEffect(0.5)
                                    .offset(x:deviceWidth/10)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
            }
        }
        .sheet(isPresented: self.$showCharactersMenu){
            CharactersMenuView()
        }
        .sheet(isPresented: self.$showLeaderBoard){
            LeaderBoardView()
        }
        .edgesIgnoringSafeArea(.all)
        .allowsHitTesting(!freezeScrolling)
        .onAppear {
            playedCharacter = appModel.selectedCharacter
            if let music = Bundle.main.path(forResource: "FallBallOST120", ofType: "mp3"){
                do {
                    self.musicPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: music))
                    self.musicPlayer.numberOfLoops = -1
                    if appModel.mute == true {
                        self.musicPlayer.setVolume(0, fadeDuration: 0)
                    } else {
                        self.musicPlayer.setVolume(1, fadeDuration: 0)
                    }
                    self.musicPlayer.play()
                } catch {
                    print("Error playing audio: \(error)")
                }
            }
            if let punch = Bundle.main.path(forResource: "punch", ofType: "mp3"){
                do {
                    self.punchSoundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: punch))
                    if appModel.mute == true {
                        self.punchSoundEffect.setVolume(0, fadeDuration: 0)
                    } else {
                        self.punchSoundEffect.setVolume(1, fadeDuration: 0)
                    }
                } catch {
                    print("Error playing audio: \(error)")
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
