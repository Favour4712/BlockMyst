import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ScrollView,
  Alert,
  Modal,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withSequence,
  withTiming,
} from "react-native-reanimated";
import { useNavigation, useRoute, RouteProp } from "@react-navigation/native";
import { GameStackParamList } from "../navigation/GameNavigator";
import { useGame } from "../context/GameContext";
import LottieAnimation from "../components/LottieAnimation";

// Import animations
const confettiAnimation = require("../assets/animations/Confetti.json");
const moneyRainAnimation = require("../assets/animations/Money rain.json");

type PuzzleScreenRouteProp = RouteProp<GameStackParamList, "Puzzle">;

// Mock puzzle data
const MOCK_PUZZLES = {
  1: {
    title: "Hash Hunter",
    description: "Find the missing byte in this blockchain hash",
    question: "What is the missing byte? 0x742d35Cc6634C0532925a3b844Bc9e7595f0b__",
    answer: "eb",
    hint: "Think about hexadecimal patterns...",
    reward: 500,
    xp: 100,
  },
};

export default function PuzzleScreen() {
  const navigation = useNavigation();
  const route = useRoute<PuzzleScreenRouteProp>();
  const { playerStats, updateStats } = useGame();
  const { puzzleId } = route.params;

  const puzzle = MOCK_PUZZLES[puzzleId as keyof typeof MOCK_PUZZLES];

  const [userAnswer, setUserAnswer] = useState("");
  const [hintsUsed, setHintsUsed] = useState(0);
  const [showHint, setShowHint] = useState(false);
  const [timeLeft, setTimeLeft] = useState(300); // 5 minutes
  const [showVictory, setShowVictory] = useState(false);

  const shakeAnimation = useSharedValue(0);
  const successScale = useSharedValue(1);

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const animatedShakeStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: shakeAnimation.value }],
  }));

  const animatedSuccessStyle = useAnimatedStyle(() => ({
    transform: [{ scale: successScale.value }],
  }));

  const handleSubmit = () => {
    if (userAnswer.toLowerCase() === puzzle.answer.toLowerCase()) {
      // Correct answer!
      successScale.value = withSequence(
        withSpring(1.2),
        withSpring(1)
      );
      
      const finalReward = hintsUsed > 0 ? puzzle.reward * 0.9 : puzzle.reward;
      
      // Show victory animation
      setShowVictory(true);
      
      // Update stats after 2 seconds
      setTimeout(() => {
        updateStats({
          points: playerStats.points + Math.floor(finalReward),
          experience: playerStats.experience + puzzle.xp,
          puzzlesSolved: playerStats.puzzlesSolved + 1,
        });
        setShowVictory(false);
        navigation.goBack();
      }, 3000);
    } else {
      // Wrong answer
      shakeAnimation.value = withSequence(
        withTiming(10, { duration: 50 }),
        withTiming(-10, { duration: 50 }),
        withTiming(10, { duration: 50 }),
        withTiming(0, { duration: 50 })
      );
      Alert.alert("❌ INCORRECT", "Try again!");
    }
  };

  const handleHint = () => {
    if (hintsUsed < 3) {
      setHintsUsed(hintsUsed + 1);
      setShowHint(true);
      Alert.alert("💡 HINT", puzzle.hint);
    } else {
      Alert.alert("⚠️ No Hints Left", "You've used all available hints!");
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  };

  return (
    <LinearGradient
      colors={["#0a0e27", "#1a1f3a", "#2a0e3a"]}
      style={styles.container}
    >
      <ScrollView contentContainerStyle={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <Text style={styles.backButton}>← BACK</Text>
          </TouchableOpacity>
          <View style={styles.timerContainer}>
            <Text style={styles.timer}>⏱️ {formatTime(timeLeft)}</Text>
          </View>
        </View>

        {/* Puzzle Card */}
        <Animated.View style={[styles.puzzleCard, animatedSuccessStyle]}>
          <Text style={styles.puzzleTitle}>{puzzle.title}</Text>
          <Text style={styles.puzzleDescription}>{puzzle.description}</Text>

          <View style={styles.questionBox}>
            <Text style={styles.questionText}>{puzzle.question}</Text>
          </View>

          {/* Stats */}
          <View style={styles.statsRow}>
            <View style={styles.statBox}>
              <Text style={styles.statLabel}>REWARD</Text>
              <Text style={styles.statValue}>🪙 {puzzle.reward}</Text>
            </View>
            <View style={styles.statBox}>
              <Text style={styles.statLabel}>XP</Text>
              <Text style={styles.statValue}>⚡ {puzzle.xp}</Text>
            </View>
            <View style={styles.statBox}>
              <Text style={styles.statLabel}>HINTS</Text>
              <Text style={styles.statValue}>💡 {3 - hintsUsed}</Text>
            </View>
          </View>
        </Animated.View>

        {/* Answer Input */}
        <Animated.View style={[styles.answerSection, animatedShakeStyle]}>
          <Text style={styles.answerLabel}>YOUR ANSWER:</Text>
          <TextInput
            style={styles.input}
            placeholder="Type your answer..."
            placeholderTextColor="#666"
            value={userAnswer}
            onChangeText={setUserAnswer}
            autoCapitalize="none"
            autoCorrect={false}
          />
        </Animated.View>

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity
            style={styles.hintButton}
            onPress={handleHint}
            disabled={hintsUsed >= 3}
          >
            <Text style={styles.hintButtonText}>💡 HINT</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.submitButton}
            onPress={handleSubmit}
            disabled={!userAnswer.trim()}
          >
            <LinearGradient
              colors={["#00ff88", "#00cc6a"]}
              style={styles.submitGradient}
            >
              <Text style={styles.submitButtonText}>⚡ SUBMIT ⚡</Text>
            </LinearGradient>
          </TouchableOpacity>
        </View>

        {/* Hint Display */}
        {showHint && (
          <View style={styles.hintBox}>
            <Text style={styles.hintText}>💡 {puzzle.hint}</Text>
          </View>
        )}
      </ScrollView>

      {/* Victory Modal */}
      <Modal visible={showVictory} transparent animationType="fade">
        <View style={styles.victoryModal}>
          <LottieAnimation
            source={confettiAnimation}
            autoPlay
            loop={false}
            style={styles.confettiAnimation}
          />
          <View style={styles.victoryContent}>
            <Text style={styles.victoryTitle}>🎉 SOLVED! 🎉</Text>
            <LottieAnimation
              source={moneyRainAnimation}
              autoPlay
              loop
              style={styles.moneyAnimation}
            />
            <Text style={styles.victoryReward}>
              +{Math.floor(hintsUsed > 0 ? puzzle.reward * 0.9 : puzzle.reward)} PTS
            </Text>
            <Text style={styles.victoryXP}>+{puzzle.xp} XP</Text>
          </View>
        </View>
      </Modal>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    padding: 20,
    paddingTop: 60,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 30,
  },
  backButton: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
  timerContainer: {
    backgroundColor: "rgba(255, 23, 68, 0.2)",
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: "#ff1744",
  },
  timer: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#ff1744",
  },
  puzzleCard: {
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 20,
    padding: 25,
    marginBottom: 30,
    borderWidth: 3,
    borderColor: "#00ff88",
  },
  puzzleTitle: {
    fontSize: 20,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    textAlign: "center",
    marginBottom: 15,
  },
  puzzleDescription: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#aaa",
    textAlign: "center",
    marginBottom: 20,
    lineHeight: 18,
  },
  questionBox: {
    backgroundColor: "rgba(0, 255, 136, 0.1)",
    padding: 20,
    borderRadius: 15,
    borderWidth: 2,
    borderColor: "#00ff88",
    marginBottom: 20,
  },
  questionText: {
    fontSize: 11,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    lineHeight: 20,
  },
  statsRow: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  statBox: {
    flex: 1,
    alignItems: "center",
  },
  statLabel: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
    marginBottom: 5,
  },
  statValue: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
  },
  answerSection: {
    marginBottom: 30,
  },
  answerLabel: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
    marginBottom: 15,
  },
  input: {
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 15,
    padding: 20,
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    borderWidth: 2,
    borderColor: "#00ff88",
  },
  actions: {
    flexDirection: "row",
    gap: 15,
  },
  hintButton: {
    flex: 1,
    backgroundColor: "rgba(255, 215, 0, 0.2)",
    borderRadius: 15,
    padding: 20,
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#ffd700",
  },
  hintButtonText: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
  },
  submitButton: {
    flex: 2,
    borderRadius: 15,
    overflow: "hidden",
  },
  submitGradient: {
    padding: 20,
    alignItems: "center",
  },
  submitButtonText: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
  },
  hintBox: {
    backgroundColor: "rgba(255, 215, 0, 0.1)",
    padding: 20,
    borderRadius: 15,
    borderWidth: 2,
    borderColor: "#ffd700",
    marginTop: 20,
  },
  hintText: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    lineHeight: 18,
  },
  victoryModal: {
    flex: 1,
    backgroundColor: "rgba(0, 0, 0, 0.95)",
    justifyContent: "center",
    alignItems: "center",
  },
  confettiAnimation: {
    position: "absolute",
    width: "100%",
    height: "100%",
  },
  victoryContent: {
    alignItems: "center",
    zIndex: 10,
  },
  victoryTitle: {
    fontSize: 28,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
    marginBottom: 30,
    textShadowColor: "#00ff88",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 20,
  },
  moneyAnimation: {
    width: 300,
    height: 300,
    marginBottom: 20,
  },
  victoryReward: {
    fontSize: 32,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    marginBottom: 10,
  },
  victoryXP: {
    fontSize: 20,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
});

