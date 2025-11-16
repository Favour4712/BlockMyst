import React from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useNavigation } from "@react-navigation/native";
import { useGame } from "../context/GameContext";
import LottieAnimation from "../components/LottieAnimation";

// Import animations
const trophyAnimation = require("../assets/animations/Trophy.json");

// Mock leaderboard data
const MOCK_LEADERBOARD = [
  { rank: 1, username: "BlockWizard", points: 15420, level: 24, emoji: "🥇" },
  { rank: 2, username: "CryptoNinja", points: 14890, level: 23, emoji: "🥈" },
  { rank: 3, username: "ChainMaster", points: 13750, level: 22, emoji: "🥉" },
  { rank: 4, username: "HashHero", points: 12340, level: 21, emoji: "⭐" },
  { rank: 5, username: "TokenKing", points: 11890, level: 20, emoji: "⭐" },
  { rank: 6, username: "NFTQueen", points: 10250, level: 19, emoji: "💎" },
  { rank: 7, username: "DeFiLord", points: 9780, level: 18, emoji: "💎" },
  { rank: 8, username: "GasOptimizer", points: 9100, level: 17, emoji: "💎" },
  { rank: 9, username: "SmartContract", points: 8920, level: 16, emoji: "🔥" },
  { rank: 10, username: "Web3Warrior", points: 8750, level: 15, emoji: "🔥" },
];

export default function LeaderboardScreen() {
  const navigation = useNavigation();
  const { playerStats } = useGame();

  const getRankColor = (rank: number) => {
    if (rank === 1) return ["#ffd700", "#ffed4e"];
    if (rank === 2) return ["#c0c0c0", "#e8e8e8"];
    if (rank === 3) return ["#cd7f32", "#e89968"];
    return ["#2979ff", "#00b0ff"];
  };

  return (
    <LinearGradient
      colors={["#0a0e27", "#1a1f3a", "#0a0e27"]}
      style={styles.container}
    >
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← BACK</Text>
        </TouchableOpacity>
        <View style={styles.titleContainer}>
          <LottieAnimation
            source={trophyAnimation}
            autoPlay
            loop
            style={styles.trophyAnimation}
          />
          <Text style={styles.title}>LEADERBOARD</Text>
        </View>
        <View style={{ width: 60 }} />
      </View>

      {/* Your Rank Card */}
      <View style={styles.yourRankCard}>
        <LinearGradient
          colors={["#00ff88", "#00cc6a"]}
          style={styles.yourRankGradient}
        >
          <Text style={styles.yourRankLabel}>YOUR RANK</Text>
          <Text style={styles.yourRankValue}>#{playerStats.rank}</Text>
          <Text style={styles.yourRankPoints}>{playerStats.points} PTS</Text>
        </LinearGradient>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.leaderboardList}
        showsVerticalScrollIndicator={false}
      >
        {MOCK_LEADERBOARD.map((player, index) => (
          <View key={player.rank} style={styles.playerCard}>
            <LinearGradient
              colors={getRankColor(player.rank)}
              style={styles.rankBadge}
            >
              <Text style={styles.rankEmoji}>{player.emoji}</Text>
              <Text style={styles.rankNumber}>#{player.rank}</Text>
            </LinearGradient>

            <View style={styles.playerInfo}>
              <Text style={styles.playerUsername}>{player.username}</Text>
              <View style={styles.playerStats}>
                <Text style={styles.playerLevel}>LVL {player.level}</Text>
                <Text style={styles.playerPoints}>
                  {player.points.toLocaleString()} PTS
                </Text>
              </View>
            </View>
          </View>
        ))}
      </ScrollView>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingTop: 60,
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  backButton: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
  titleContainer: {
    alignItems: "center",
  },
  trophyAnimation: {
    width: 60,
    height: 60,
    marginBottom: -10,
  },
  title: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    textAlign: "center",
  },
  yourRankCard: {
    marginHorizontal: 20,
    marginBottom: 30,
    borderRadius: 20,
    overflow: "hidden",
  },
  yourRankGradient: {
    padding: 25,
    alignItems: "center",
  },
  yourRankLabel: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
    marginBottom: 10,
  },
  yourRankValue: {
    fontSize: 32,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
    marginBottom: 5,
  },
  yourRankPoints: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
  },
  scrollView: {
    flex: 1,
  },
  leaderboardList: {
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  playerCard: {
    flexDirection: "row",
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 15,
    padding: 15,
    marginBottom: 15,
    borderWidth: 2,
    borderColor: "#333",
    alignItems: "center",
  },
  rankBadge: {
    width: 70,
    height: 70,
    borderRadius: 35,
    alignItems: "center",
    justifyContent: "center",
    marginRight: 15,
  },
  rankEmoji: {
    fontSize: 24,
    marginBottom: 2,
  },
  rankNumber: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
  },
  playerInfo: {
    flex: 1,
  },
  playerUsername: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    marginBottom: 8,
  },
  playerStats: {
    flexDirection: "row",
    gap: 15,
  },
  playerLevel: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
  playerPoints: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
  },
});

