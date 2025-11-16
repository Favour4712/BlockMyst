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

// Mock guild data
const TOP_GUILDS = [
  {
    name: "Cipher Knights",
    members: 156,
    points: 42500,
    level: 15,
    emoji: "🛡️",
  },
  {
    name: "Hash Heroes",
    members: 142,
    points: 39800,
    level: 14,
    emoji: "⚔️",
  },
  {
    name: "Block Wizards",
    members: 128,
    points: 35200,
    level: 13,
    emoji: "🧙",
  },
];

export default function GuildScreen() {
  const navigation = useNavigation();
  const { playerStats } = useGame();

  return (
    <LinearGradient
      colors={["#0a0e27", "#1a1f3a", "#0a0e27"]}
      style={styles.container}
    >
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← BACK</Text>
        </TouchableOpacity>
        <Text style={styles.title}>🏰 GUILDS</Text>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Your Guild */}
        {playerStats.guild && (
          <View style={styles.yourGuildCard}>
            <LinearGradient
              colors={["#00bfa5", "#00e676"]}
              style={styles.yourGuildGradient}
            >
              <Text style={styles.yourGuildEmoji}>🏰</Text>
              <Text style={styles.yourGuildName}>{playerStats.guild}</Text>
              <Text style={styles.yourGuildRole}>MEMBER</Text>
            </LinearGradient>
          </View>
        )}

        {/* Top Guilds */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🏆 TOP GUILDS</Text>
          {TOP_GUILDS.map((guild, index) => (
            <View key={guild.name} style={styles.guildCard}>
              <View style={styles.guildRank}>
                <Text style={styles.guildRankNumber}>#{index + 1}</Text>
              </View>

              <View style={styles.guildIconContainer}>
                <LinearGradient
                  colors={["#2979ff", "#00b0ff"]}
                  style={styles.guildIcon}
                >
                  <Text style={styles.guildEmoji}>{guild.emoji}</Text>
                </LinearGradient>
              </View>

              <View style={styles.guildInfo}>
                <Text style={styles.guildName}>{guild.name}</Text>
                <View style={styles.guildStats}>
                  <Text style={styles.guildStat}>
                    👥 {guild.members} members
                  </Text>
                  <Text style={styles.guildStat}>
                    🪙 {guild.points.toLocaleString()}
                  </Text>
                  <Text style={styles.guildStat}>LVL {guild.level}</Text>
                </View>
              </View>

              {playerStats.guild !== guild.name && (
                <TouchableOpacity style={styles.joinButton}>
                  <Text style={styles.joinButtonText}>JOIN</Text>
                </TouchableOpacity>
              )}
            </View>
          ))}
        </View>

        {/* Guild Benefits */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>✨ GUILD BENEFITS</Text>
          <Text style={styles.infoText}>
            • Team up with other players{"\n"}• Share rewards and bonuses{"\n"}•
            Access exclusive tournaments{"\n"}• Unlock special achievements
            {"\n"}• Collaborate on tough puzzles
          </Text>
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
  yourGuildCard: {
    borderRadius: 20,
    overflow: "hidden",
    marginBottom: 30,
  },
  yourGuildGradient: {
    padding: 30,
    alignItems: "center",
  },
  yourGuildEmoji: {
    fontSize: 48,
    marginBottom: 15,
  },
  yourGuildName: {
    fontSize: 18,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
    marginBottom: 5,
    textShadowColor: "#000",
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 0,
  },
  yourGuildRole: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    opacity: 0.8,
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
  guildCard: {
    flexDirection: "row",
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 15,
    padding: 15,
    marginBottom: 15,
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#333",
  },
  guildRank: {
    width: 40,
    alignItems: "center",
  },
  guildRankNumber: {
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
  },
  guildIconContainer: {
    marginRight: 15,
  },
  guildIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 2,
    borderColor: "#fff",
  },
  guildEmoji: {
    fontSize: 28,
  },
  guildInfo: {
    flex: 1,
  },
  guildName: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    marginBottom: 8,
  },
  guildStats: {
    flexDirection: "row",
    gap: 10,
  },
  guildStat: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
  },
  joinButton: {
    backgroundColor: "rgba(0, 255, 136, 0.2)",
    paddingHorizontal: 15,
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: "#00ff88",
  },
  joinButtonText: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
  infoCard: {
    backgroundColor: "rgba(0, 191, 165, 0.1)",
    borderRadius: 20,
    padding: 20,
    borderWidth: 2,
    borderColor: "#00bfa5",
  },
  infoTitle: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#00bfa5",
    marginBottom: 15,
  },
  infoText: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#00bfa5",
    lineHeight: 20,
  },
});
