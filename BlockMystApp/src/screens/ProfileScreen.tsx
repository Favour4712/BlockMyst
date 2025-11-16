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

// Mock NFT data
const MOCK_NFTS = [
  { id: 1, name: "Golden Cipher", rarity: "Legendary", emoji: "🏆" },
  { id: 2, name: "Crystal Key", rarity: "Epic", emoji: "💎" },
  { id: 3, name: "Fire Token", rarity: "Rare", emoji: "🔥" },
  { id: 4, name: "Ice Shield", rarity: "Rare", emoji: "🛡️" },
  { id: 5, name: "Thunder Bolt", rarity: "Epic", emoji: "⚡" },
  { id: 6, name: "Star Compass", rarity: "Rare", emoji: "⭐" },
];

const ACHIEVEMENTS = [
  { title: "First Blood", desc: "Solve 1st puzzle", emoji: "🎯", unlocked: true },
  { title: "Speed Demon", desc: "Solve in <60s", emoji: "⚡", unlocked: true },
  { title: "Combo King", desc: "5 in a row", emoji: "🔥", unlocked: true },
  { title: "Guild Master", desc: "Join a guild", emoji: "🏰", unlocked: false },
];

export default function ProfileScreen() {
  const navigation = useNavigation();
  const { playerStats } = useGame();

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case "Legendary":
        return ["#ffd700", "#ffed4e"];
      case "Epic":
        return ["#d500f9", "#aa00ff"];
      case "Rare":
        return ["#2979ff", "#00b0ff"];
      default:
        return ["#666", "#888"];
    }
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
        <Text style={styles.title}>👤 PROFILE</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Player Card */}
        <View style={styles.playerCard}>
          <View style={styles.avatarContainer}>
            <LinearGradient
              colors={["#00ff88", "#00cc6a"]}
              style={styles.avatar}
            >
              <Text style={styles.avatarEmoji}>👤</Text>
            </LinearGradient>
          </View>

          <Text style={styles.username}>{playerStats.username}</Text>
          <Text style={styles.address}>
            {playerStats.address.slice(0, 6)}...{playerStats.address.slice(-4)}
          </Text>

          {/* Stats Grid */}
          <View style={styles.statsGrid}>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{playerStats.level}</Text>
              <Text style={styles.statLabel}>LEVEL</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{playerStats.points}</Text>
              <Text style={styles.statLabel}>POINTS</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>#{playerStats.rank}</Text>
              <Text style={styles.statLabel}>RANK</Text>
            </View>
            <View style={styles.statCard}>
              <Text style={styles.statValue}>{playerStats.puzzlesSolved}</Text>
              <Text style={styles.statLabel}>SOLVED</Text>
            </View>
          </View>

          {/* Guild Badge */}
          {playerStats.guild && (
            <View style={styles.guildBadge}>
              <Text style={styles.guildText}>🏰 {playerStats.guild}</Text>
            </View>
          )}
        </View>

        {/* NFT Collection */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🎨 NFT COLLECTION</Text>
          <View style={styles.nftGrid}>
            {MOCK_NFTS.map((nft) => (
              <View key={nft.id} style={styles.nftCard}>
                <LinearGradient
                  colors={getRarityColor(nft.rarity)}
                  style={styles.nftGradient}
                >
                  <Text style={styles.nftEmoji}>{nft.emoji}</Text>
                  <Text style={styles.nftName}>{nft.name}</Text>
                  <Text style={styles.nftRarity}>{nft.rarity}</Text>
                </LinearGradient>
              </View>
            ))}
          </View>
        </View>

        {/* Achievements */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🏅 ACHIEVEMENTS</Text>
          {ACHIEVEMENTS.map((achievement, index) => (
            <View
              key={index}
              style={[
                styles.achievementCard,
                !achievement.unlocked && styles.achievementLocked,
              ]}
            >
              <Text style={styles.achievementEmoji}>{achievement.emoji}</Text>
              <View style={styles.achievementInfo}>
                <Text
                  style={[
                    styles.achievementTitle,
                    !achievement.unlocked && styles.achievementLockedText,
                  ]}
                >
                  {achievement.title}
                </Text>
                <Text
                  style={[
                    styles.achievementDesc,
                    !achievement.unlocked && styles.achievementLockedText,
                  ]}
                >
                  {achievement.desc}
                </Text>
              </View>
              {achievement.unlocked && (
                <Text style={styles.checkmark}>✓</Text>
              )}
            </View>
          ))}
        </View>
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
  title: {
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
  },
  scrollView: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  playerCard: {
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 20,
    padding: 25,
    alignItems: "center",
    marginBottom: 30,
    borderWidth: 3,
    borderColor: "#00ff88",
  },
  avatarContainer: {
    marginBottom: 20,
  },
  avatar: {
    width: 100,
    height: 100,
    borderRadius: 50,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 4,
    borderColor: "#fff",
  },
  avatarEmoji: {
    fontSize: 48,
  },
  username: {
    fontSize: 18,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    marginBottom: 10,
  },
  address: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
    marginBottom: 20,
  },
  statsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 15,
    marginBottom: 20,
  },
  statCard: {
    backgroundColor: "rgba(0, 255, 136, 0.1)",
    borderRadius: 15,
    padding: 15,
    alignItems: "center",
    width: "45%",
    borderWidth: 2,
    borderColor: "#00ff88",
  },
  statValue: {
    fontSize: 20,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
    marginBottom: 5,
  },
  statLabel: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
  },
  guildBadge: {
    backgroundColor: "rgba(0, 191, 165, 0.2)",
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 2,
    borderColor: "#00bfa5",
  },
  guildText: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#00bfa5",
  },
  section: {
    marginBottom: 30,
  },
  sectionTitle: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    marginBottom: 20,
  },
  nftGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 15,
  },
  nftCard: {
    width: "30%",
    aspectRatio: 1,
    borderRadius: 15,
    overflow: "hidden",
  },
  nftGradient: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },
  nftEmoji: {
    fontSize: 32,
    marginBottom: 5,
  },
  nftName: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
  },
  nftRarity: {
    fontSize: 6,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    marginTop: 2,
  },
  achievementCard: {
    flexDirection: "row",
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 15,
    padding: 15,
    marginBottom: 15,
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#00ff88",
  },
  achievementLocked: {
    opacity: 0.4,
    borderColor: "#333",
  },
  achievementEmoji: {
    fontSize: 32,
    marginRight: 15,
  },
  achievementInfo: {
    flex: 1,
  },
  achievementTitle: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    marginBottom: 5,
  },
  achievementDesc: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
  },
  achievementLockedText: {
    color: "#555",
  },
  checkmark: {
    fontSize: 24,
    color: "#00ff88",
  },
});

