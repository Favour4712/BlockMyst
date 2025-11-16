import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import { useNavigation } from "@react-navigation/native";
import LottieAnimation from "../components/LottieAnimation";

// Import animations
const battleAnimation = require("../assets/animations/Battle.json");

// Mock battle data
const ACTIVE_BATTLES = [
  {
    id: 1,
    name: "CRYPTO CLASH",
    players: 8,
    maxPlayers: 10,
    prize: 5000,
    timeLeft: "2:45:00",
    difficulty: "Hard",
  },
  {
    id: 2,
    name: "HASH WARS",
    players: 12,
    maxPlayers: 20,
    prize: 10000,
    timeLeft: "5:15:00",
    difficulty: "Expert",
  },
];

const UPCOMING_BATTLES = [
  {
    id: 3,
    name: "MEGA SHOWDOWN",
    maxPlayers: 50,
    prize: 50000,
    startsIn: "24:00:00",
    difficulty: "Legendary",
  },
];

export default function BattleRoyaleScreen() {
  const navigation = useNavigation();
  const [selectedBattle, setSelectedBattle] = useState<number | null>(null);

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case "Hard":
        return ["#ff1744", "#f50057"];
      case "Expert":
        return ["#d500f9", "#aa00ff"];
      case "Legendary":
        return ["#ffd700", "#ffed4e"];
      default:
        return ["#2979ff", "#00b0ff"];
    }
  };

  return (
    <LinearGradient
      colors={["#0a0e27", "#2a0e3a", "#0a0e27"]}
      style={styles.container}
    >
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← BACK</Text>
        </TouchableOpacity>
        <View style={styles.titleContainer}>
          <LottieAnimation
            source={battleAnimation}
            autoPlay
            loop
            style={styles.battleAnimation}
          />
          <Text style={styles.title}>BATTLE ROYALE</Text>
        </View>
        <View style={{ width: 60 }} />
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        {/* Active Battles */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>🔥 ACTIVE BATTLES</Text>
          {ACTIVE_BATTLES.map((battle) => (
            <TouchableOpacity
              key={battle.id}
              activeOpacity={0.8}
              onPress={() => setSelectedBattle(battle.id)}
            >
              <View
                style={[
                  styles.battleCard,
                  selectedBattle === battle.id && styles.battleCardSelected,
                ]}
              >
                <View style={styles.battleHeader}>
                  <Text style={styles.battleName}>{battle.name}</Text>
                  <LinearGradient
                    colors={getDifficultyColor(battle.difficulty)}
                    style={styles.difficultyBadge}
                  >
                    <Text style={styles.difficultyText}>
                      {battle.difficulty}
                    </Text>
                  </LinearGradient>
                </View>

                <View style={styles.battleStats}>
                  <View style={styles.battleStat}>
                    <Text style={styles.battleStatLabel}>PLAYERS</Text>
                    <Text style={styles.battleStatValue}>
                      {battle.players}/{battle.maxPlayers}
                    </Text>
                  </View>
                  <View style={styles.battleStat}>
                    <Text style={styles.battleStatLabel}>PRIZE</Text>
                    <Text style={styles.battleStatValue}>
                      🪙 {battle.prize}
                    </Text>
                  </View>
                  <View style={styles.battleStat}>
                    <Text style={styles.battleStatLabel}>TIME LEFT</Text>
                    <Text style={styles.battleStatValue}>
                      ⏱️ {battle.timeLeft}
                    </Text>
                  </View>
                </View>

                {selectedBattle === battle.id && (
                  <TouchableOpacity style={styles.joinButton}>
                    <LinearGradient
                      colors={["#00ff88", "#00cc6a"]}
                      style={styles.joinGradient}
                    >
                      <Text style={styles.joinButtonText}>⚔️ JOIN BATTLE</Text>
                    </LinearGradient>
                  </TouchableOpacity>
                )}
              </View>
            </TouchableOpacity>
          ))}
        </View>

        {/* Upcoming Battles */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>⏰ UPCOMING</Text>
          {UPCOMING_BATTLES.map((battle) => (
            <View key={battle.id} style={styles.upcomingCard}>
              <LinearGradient
                colors={getDifficultyColor(battle.difficulty)}
                style={styles.upcomingGradient}
              >
                <Text style={styles.upcomingName}>{battle.name}</Text>
                <View style={styles.upcomingStats}>
                  <Text style={styles.upcomingStat}>
                    👥 {battle.maxPlayers} MAX
                  </Text>
                  <Text style={styles.upcomingStat}>🪙 {battle.prize}</Text>
                </View>
                <Text style={styles.upcomingTimer}>
                  STARTS IN: {battle.startsIn}
                </Text>
              </LinearGradient>
            </View>
          ))}
        </View>

        {/* How to Play */}
        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>📖 HOW TO PLAY</Text>
          <Text style={styles.infoText}>
            • Join battles with other players{"\n"}
            • Solve puzzles faster than opponents{"\n"}
            • Last player standing wins!{"\n"}
            • Higher difficulty = bigger rewards
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
  titleContainer: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  battleAnimation: {
    width: 50,
    height: 50,
  },
  title: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#ff1744",
  },
  scrollView: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 20,
    paddingBottom: 40,
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
  battleCard: {
    backgroundColor: "rgba(26, 31, 58, 0.9)",
    borderRadius: 20,
    padding: 20,
    marginBottom: 15,
    borderWidth: 2,
    borderColor: "#333",
  },
  battleCardSelected: {
    borderColor: "#00ff88",
    shadowColor: "#00ff88",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 10,
  },
  battleHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  battleName: {
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
  },
  difficultyBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 10,
  },
  difficultyText: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
  },
  battleStats: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  battleStat: {
    alignItems: "center",
  },
  battleStatLabel: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
    marginBottom: 5,
  },
  battleStatValue: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
  },
  joinButton: {
    marginTop: 20,
    borderRadius: 15,
    overflow: "hidden",
  },
  joinGradient: {
    padding: 15,
    alignItems: "center",
  },
  joinButtonText: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#000",
  },
  upcomingCard: {
    borderRadius: 20,
    overflow: "hidden",
    marginBottom: 15,
  },
  upcomingGradient: {
    padding: 25,
    borderWidth: 3,
    borderColor: "#fff",
    borderRadius: 20,
  },
  upcomingName: {
    fontSize: 18,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
    marginBottom: 15,
    textShadowColor: "#000",
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 0,
  },
  upcomingStats: {
    flexDirection: "row",
    justifyContent: "center",
    gap: 20,
    marginBottom: 10,
  },
  upcomingStat: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
  },
  upcomingTimer: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
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

