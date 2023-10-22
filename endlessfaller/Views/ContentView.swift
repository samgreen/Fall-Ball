//
//  ContentView.swift
//  endlessfaller
//
//  Created by Wheezy Salem on 7/12/23.
//

import SwiftUI
import VTabView
import AudioToolbox
import AVFoundation
import GameKit
import AudioToolbox


let bestScoreKey = "bestscorekey"
let levels = 1000
let difficulty = 8

struct ContentView: View {
    
    let deviceHeight = UIScreen.main.bounds.height
    let deviceWidth = UIScreen.main.bounds.width
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    let modelName = UIDevice.modelName
    @AppStorage(bestScoreKey) var bestScore: Int = UserDefaults.standard.integer(forKey: bestScoreKey)
    @StateObject var appModel = AppModel()
    @ObservedObject private var timerManager = TimerManager()
    @ObservedObject var gameCenter = GameCenter()
    @State var score: Int = 0
    @State var highestScoreInGame: Int = -1
    @State var currentScore: Int = 0
    @State var currentIndex: Int = -1
    @State var costToContinue: Int = 1
    @State var speed: Double = 4
    @State var fraction: Double = 0.5
    @State var gameOver = false
    @State var freezeScrolling = false
    @State var showCharactersMenu = false
    @State var showLeaderBoard = false
    @State var showNewBestScore = false
    @State var showPlaqueShare = false
    @State var showCurrencyPage = false
    @State var showContinueToPlayBanner = false
    @State var gameShouldBeOver = false
    @State var showWastedScreen = false
    @State var muteIsPressed = false
    @State var ballButtonIsPressed = false
    @State var currencyButtonIsPressed = false
    @State var plaqueIsPressed = false
    @State var levelYPosition: CGFloat = 0
    @State var gameOverBackgroundColor: Color = .white
    @State var playedCharacter = ""
    @State var musicPlayer: AVAudioPlayer!
    @State var punchSoundEffect: AVAudioPlayer!
    @State var placeOnLeaderBoard = 0
    @State var isBallButtonMovingUp = false
    @State var isSwipeBannerMovingUp = false
    @State var colors: [Color] = (1...levels).map { _ in
        Color(red: .random(in: 0.1...1), green: .random(in: 0.1...1), blue: .random(in: 0.1...1))
    }
    
    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    func dropBall() {
        timerManager.startTimer(speed: speed)
    }
    
    func gameOverOperations() {
        self.punchSoundEffect.play()
        gameOverBackgroundColor = colors[currentIndex]
        showNewBestScore = false
        gameOver = true
        currentScore = highestScoreInGame
        if currentScore > bestScore {
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
            DispatchQueue.main.async{
                bestScore = currentScore
            }
        }
        freezeScrolling = true
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) {}
        showWastedScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.colors = (1...levels).map { _ in
                Color(red: .random(in: 0.1...1), green: .random(in: 0.1...1), blue: .random(in: 0.1...1))
            }
            freezeScrolling = false
            self.speed = 4
            self.fraction = 0.5
        }
        gameShouldBeOver = false
        self.playedCharacter = appModel.selectedCharacter
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            showWastedScreen = false
            self.currentIndex = -1
            highestScoreInGame = -1
            DispatchQueue.main.async{
                gameCenter.updateScore(currentScore: currentScore, bestScore: bestScore, ballID: appModel.selectedCharacter)
            }
            timer.invalidate() // Stop the timer after the reset
        }
    }
    
    let impactMed = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        ScrollView {
            ZStack{
                VTabView(selection: $currentIndex) {
                    VStack{
                        Spacer()
                        if !gameOver {
                            VStack{
                                Text("Swipe up \nto play!")
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.black)
                                    .padding()
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.black)
                            }
                            .animatedOffset(speed: 1)
                            .bold()
                            .font(.largeTitle)
                            .scaleEffect(1.5)
                            .tag(-1)
                        } else {
                            VStack{
                                HStack{
                                    Spacer()
                                    HStack{
                                        BoinsView()
                                        Text(String(appModel.balance))
                                            .bold()
                                            .italic()
                                            .font(.largeTitle)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                                    .background{
                                        Color.white
                                    }
                                    .cornerRadius(15)
                                    .shadow(color: .black, radius: 0.1, x: currencyButtonIsPressed ? 0 : -6, y: currencyButtonIsPressed ? 0 : 6)
                                    .offset(x: currencyButtonIsPressed ? -6 : 0, y: currencyButtonIsPressed ? 6 : 0)
                                    .padding()
                                    .pressEvents {
                                        // On press
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            currencyButtonIsPressed = true
                                        }
                                    } onRelease: {
                                        withAnimation {
                                            currencyButtonIsPressed = false
                                            showCurrencyPage = true
                                        }
                                    }
                                }
                                .padding(.top, 30)
                                Spacer()
                                Text("Game Over!")
                                    .italic()
                                    .bold()
                                    .font(idiom == .pad ? .largeTitle : .system(size: deviceWidth * 0.08))
//                                    .randomColor()
                                    .scaleEffect(1.8)
//                                    .shadow(color: .black, radius: 0.1, x: -3, y: 3)
                                    .padding(.bottom, deviceHeight * 0.04)
                                ZStack{
                                    HStack{
                                        VStack(alignment: .trailing){
                                            Spacer()
                                                .frame(maxHeight: 10)
                                            HStack{
                                                ZStack{
                                                    Text("Ball:")
                                                        .font(.title)
                                                        .bold()
                                                        .italic()
                                                        .foregroundColor(.black)
                                                        .padding(.leading, 15)
                                                        .offset(x: 30)
                                                }
                                                Spacer()
                                                    .frame(maxWidth: 110)
                                                Text("Score:")
                                                    .foregroundColor(.black)
                                                    .bold()
                                                    .italic()
                                            }
                                            Text(String(currentScore))
                                                .bold()
                                                .italic()
                                                .offset(y: 6)
                                                .foregroundColor(.black)
                                                .font(.largeTitle)
                                            Spacer()
                                                .frame(maxHeight: 15)
                                            Text("Best:")
                                                .foregroundColor(.black)
                                                .bold()
                                                .italic()
                                                Text(String(bestScore))
                                                    .bold()
                                                    .italic()
                                                    .offset(y: 6)
                                                    .foregroundColor(.black)
                                                    .font(.largeTitle)
                                            Spacer()
                                                .frame(maxHeight: 10)
                                        }
                                        .padding(.trailing, 30)
                                        .padding()
                                        .font(.title)
                                    }
                                    if let character = appModel.characters.first(where: { $0.characterID == playedCharacter}) {
                                        AnyView(character.character)
                                            .scaleEffect(2.4)
                                        .offset(x: -70, y: 18)
                                    }
                                }
                                .background{
                                    ZStack{
                                        Rectangle()
                                            .foregroundColor(.yellow)
                                            .cornerRadius(30)
                                            .shadow(color: .black, radius: 0.1, x: plaqueIsPressed ? 0 : -9, y: plaqueIsPressed ? 0 : 9)
                                            .padding(.horizontal,9)
                                        VStack{
                                            Spacer()
                                            HStack{
                                                Image(systemName: "square.and.arrow.up")
                                                    .bold()
                                                    .font(.title2)
                                                    .padding(15)
                                                    .padding(.horizontal, 12)
                                                Spacer()
                                            }
                                        }
                                    }

                                }
                                .offset(x: plaqueIsPressed ? -9 : 0, y: plaqueIsPressed ? 9 : 0)
                                .pressEvents {
                                    // On press
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        plaqueIsPressed = true
                                    }
                                } onRelease: {
                                    withAnimation {
                                        plaqueIsPressed = false
                                        showPlaqueShare = true
                                    }
                                }
                                
                                VStack{
                                    Text("Swipe up to \nplay again!")
                                        
                                        .italic()
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.black)
                                        .padding(.top, deviceHeight * 0.06)
                                        .padding()
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.black)
                                        //.shadow(color: .black, radius: 3)
                                }
                                .bold()
                                .foregroundColor(.primary)
                                .font(idiom == .pad ? .largeTitle : .system(size: deviceWidth * 0.1))
                                .tag(-1)
                                .animatedOffset(speed: 1)
                                Spacer()
                            }
                            .onAppear() {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: true)) {
                                    isBallButtonMovingUp.toggle()
                                }
                            }
                        }
                        Spacer()
                        if gameOver {
                            ZStack{
                                HStack{
                                    
                                    Image(systemName: appModel.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .foregroundColor(.teal)
                                        .font(.largeTitle)
                                    .shadow(color: .black, radius: 0.1, x: muteIsPressed ? 0 : -3, y: muteIsPressed ? 0 : 3)
                                        .scaleEffect(1.2)
                                        .padding(36)
                                        .offset(x: muteIsPressed ? -3 : 0, y: muteIsPressed ? 3 : 0)
                                        .pressEvents {
                                            // On press
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                muteIsPressed = true
                                            }
                                        } onRelease: {
                                            //AudioServicesPlaySystemSound(1305)
                                            withAnimation {
                                                muteIsPressed = false
                                                appModel.mute.toggle()
                                            }
                                        }
                                        .onChange(of: appModel.mute) { setting in
                                            if setting == true {
                                                self.musicPlayer.setVolume(0, fadeDuration: 0)
                                            } else {
                                                self.musicPlayer.setVolume(1, fadeDuration: 0)
                                            }
                                        }
                                    Spacer()
                                    ZStack{
//                                        Circle()
//                                            .frame(width: 46)
//                                            .offset(x:  -2, y: 2)
                                        if let character = appModel.characters.first(where: { $0.characterID == appModel.selectedCharacter}) {
                                            VStack{
                                                AnyView(character.character)
                                                    
                                                Ellipse()
                                                    .frame(width: 24, height: 6)
                                                    .blur(radius: 3)
                                            }
                                            .scaleEffect(ballButtonIsPressed ? 0.9 : 1.2)
                                        }
                                    }
                                    .padding(36)
                                    .pressEvents {
                                        // On press
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            ballButtonIsPressed = true
                                        }
                                    } onRelease: {
                                        withAnimation {
                                            ballButtonIsPressed = false
                                            showCharactersMenu = true
                                        }
                                    }
                                }
                                ZStack{
                                    PodiumView()
                                        .foregroundColor(.primary)
                                        .padding(36)
                                        .pressEvents {
                                            
                                        } onRelease: {
                                            withAnimation {
                                                showLeaderBoard = true
                                            }
                                        }
                                    if gameOver && !modelName.contains("iPhone SE") && !gameCenter.allTimePlayersList.isEmpty {
                                        HStack{
                                            Image(systemName: "arrow.down.right")
                                            Text("Top Score: " + String(gameCenter.allTimePlayersList[0].score))
                                                .italic()
                                            Image(systemName: "arrow.down.left")
                                        }
                                        .bold()
                                        .font(idiom == .pad ? .title : .title2)
                                        .offset(y: -55)
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    .background(gameOverBackgroundColor)
                    ForEach(colors.indices, id: \.self) { index in
                        ZStack{
                            colors[index]
                            if currentIndex == 0 && !showWastedScreen {
                                Instruction()
                                    .scaleEffect(1.5)
                            }
                            if currentIndex == 1 && !showWastedScreen {
                                KeepSwiping()
                                    .scaleEffect(1.5)
                            }
                            if currentIndex >= 2 && currentIndex <= 5 && !showWastedScreen {
                                SwipeFaster()
                                    .scaleEffect(1.5)
                            }
                            if highestScoreInGame == index && !showWastedScreen {
                                GeometryReader { geometry in
                                    ZStack{
                                        if !gameShouldBeOver{
                                            HStack{
                                                Divider()
                                                    .frame(width: 3)
                                                    .overlay(.black)
                                                    .offset(x: -21, y: -21)
                                                Divider()
                                                    .frame(width: 3)
                                                    .overlay(.black)
                                                    .offset(y: -39)
                                                Divider()
                                                    .frame(width: 3)
                                                    .overlay(.black)
                                                    .offset(x: 21, y: -21)
                                                
                                            }
                                            .frame(width: 66, height: abs(self.timerManager.ballYPosition * 0.1))
                                            .offset(x: 0, y:-(self.timerManager.ballYPosition * 0.1))
                                        }
                                        if let character = appModel.characters.first(where: { $0.characterID == appModel.selectedCharacter}) {
                                            AnyView(character.character)
                                                .scaleEffect(1.5)
                                                .offset(y: -12)
                                        }
                                    }
                                    .position(x: deviceWidth/2, y: self.timerManager.ballYPosition)
                                    .onChange(of: geometry.frame(in: .global).minY) { newYPosition in
                                        levelYPosition = newYPosition
                                    }
                                }
                            }
                            if index == 0{
                                ZStack{
                                    Rectangle()
                                        .frame(width: 100, height: 90)
                                        .foregroundColor(gameOverBackgroundColor)
                                    if gameOver {
                                        PodiumView()
                                            .foregroundColor(.primary)
                                            .offset(y: -9)
                                    }
                                    
                                }
                                .position(x: deviceWidth/2, y: -50)
                                
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
                    
                    gameShouldBeOver = false
                    score = newValue
                    if score > highestScoreInGame {
                        // 1052 or 1054
//                        AudioServicesPlaySystemSound(1052)
                        highestScoreInGame = score
                        if newValue < 8 {
                            speed = speed * fraction
                            fraction += 0.06
                        } else if newValue < 99 {
                            speed = speed * 0.981
                        } else {
                            speed = speed * 0.999
                        }
                        self.timerManager.ballYPosition = -23
                        dropBall()
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
                                .bold()
                                .italic()
                                .font(.system(size: 100))
                                .padding(36)
                                .padding(.top, 30)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                
                if showWastedScreen {
                    WastedView()
                } else{
                    if !showNewBestScore {
                        
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
                        NewBestScore()
                    }
                    if currentIndex > 10 {
                        CelebrationEffect()
                    }
                    if currentIndex > 40 {
                        VStack{
                            Spacer()
                            HStack{
                                Spacer()
                                BearView()
                            }
                        }
                    }
                    if currentIndex > 20 {
                        ReactionsView()
                            .offset(y: 70)
                    }
                                         if currentIndex > 60 {
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
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: self.$showCharactersMenu){
            CharactersMenuView(backgroundColor: $gameOverBackgroundColor)
        }
        .sheet(isPresented: self.$showLeaderBoard){
            GameCenterLeaderboardView(backgroundColor: $gameOverBackgroundColor)
        }
        .sheet(isPresented: self.$showPlaqueShare){
            PlayersPlaqueView(backgroundColor: $gameOverBackgroundColor)
                .presentationDetents([.height(450)])
        }
        .sheet(isPresented: self.$showCurrencyPage){
            CurrencyPageView()
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
            if let punch = Bundle.main.path(forResource: "punchSFX", ofType: "mp3"){
                do {
                    self.punchSoundEffect = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: punch))
                } catch {
                    print("Error playing audio: \(error)")
                }
            }
            if !GKLocalPlayer.local.isAuthenticated {
                gameCenter.authenticateUser()
            } else if gameCenter.todaysPlayersList.count == 0 {
                Task{
                    await gameCenter.loadLeaderboard(source: 1)
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
