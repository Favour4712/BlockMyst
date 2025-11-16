import React, { useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  Dimensions,
} from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
  withSpring,
  Easing,
} from "react-native-reanimated";
import { useNavigation } from "@react-navigation/native";
import { StackNavigationProp } from "@react-navigation/stack";
import { GameStackParamList } from "../navigation/GameNavigator";
import { useGame } from "../context/GameContext";
import LottieAnimation from "../components/LottieAnimation";

// Import animations
const loadingAnimation = require("../assets/animations/Loading.json");

const { width, height } = Dimensions.get("window");

type NavigationProp = StackNavigationProp<GameStackParamList, "IslandHub">;

const IslandButton = ({
  title,
  subtitle,
  emoji,
  color1,
  color2,
  onPress,
  delay = 0,
}: {
  title: string;
  subtitle: string;
  emoji: string;
  color1: string;
  color2: string;
  onPress: () => void;
  delay?: number;
}) => {
  const translateY = useSharedValue(0);
  const scale = useSharedValue(0);

  useEffect(() => {
    // Floating animation
    translateY.value = withRepeat(
      withTiming(15, { duration: 2000, easing: Easing.inOut(Easing.ease) }),
      -1,
      true
    );
    // Entrance animation
    setTimeout(() => {
      scale.value = withSpring(1, { damping: 8 });
    }, delay);
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }, { scale: scale.value }],
  }));

  return (
    <Animated.View style={[styles.islandContainer, animatedStyle]}>
      <TouchableOpacity activeOpacity={0.8} onPress={onPress}>
        <LinearGradient
          colors={[color1, color2]}
          style={styles.island}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          <Text style={styles.islandEmoji}>{emoji}</Text>
          <Text style={styles.islandTitle}>{title}</Text>
          <Text style={styles.islandSubtitle}>{subtitle}</Text>
        </LinearGradient>
      </TouchableOpacity>
    </Animated.View>
  );
};

export default function IslandHubScreen() {
  const navigation = useNavigation<NavigationProp>();
  const { playerStats } = useGame();

  const islands = [
    {
      title: "PUZZLES",
      subtitle: "Solve & Earn",
      emoji: "🧩",
      color1: "#ff1744",
      color2: "#f50057",
      onPress: () =>
        navigation.navigate("Puzzle", { puzzleId: 1, difficulty: "Easy" }),
    },
    {
      title: "BATTLE",
      subtitle: "PvP Arena",
      emoji: "⚔️",
      color1: "#d500f9",
      color2: "#aa00ff",
      onPress: () => navigation.navigate("BattleRoyale"),
    },
    {
      title: "GUILD",
      subtitle: "Team Up",
      emoji: "🏰",
      color1: "#00bfa5",
      color2: "#00e676",
      onPress: () => navigation.navigate("Guild"),
    },
    {
      title: "LEADERBOARD",
      subtitle: "Rankings",
      emoji: "🏆",
      color1: "#ffd600",
      color2: "#ffab00",
      onPress: () => navigation.navigate("Leaderboard"),
    },
    {
      title: "PROFILE",
      subtitle: "Your Stats",
      emoji: "👤",
      color1: "#2979ff",
      color2: "#00b0ff",
      onPress: () => navigation.navigate("Profile"),
    },
  ];

  return (
    <LinearGradient
      colors={["#0a0e27", "#1a1f3a", "#0a0e27"]}
      style={styles.container}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>⚡ BLOCKMYST ⚡</Text>
          <Text style={styles.subtitle}>CHOOSE YOUR ADVENTURE</Text>
        </View>

        {/* Player Stats Bar */}
        <View style={styles.statsBar}>
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>LEVEL</Text>
            <Text style={styles.statValue}>{playerStats.level}</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>POINTS</Text>
            <Text style={styles.statValue}>{playerStats.points}</Text>
          </View>
          <View style={styles.statDivider} />
          <View style={styles.statItem}>
            <Text style={styles.statLabel}>RANK</Text>
            <Text style={styles.statValue}>#{playerStats.rank}</Text>
          </View>
        </View>

        {/* Islands Grid */}
        <View style={styles.islandsGrid}>
          {islands.map((island, index) => (
            <IslandButton
              key={island.title}
              {...island}
              delay={index * 150}
            />
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
  scrollContent: {
    paddingTop: 60,
    paddingBottom: 40,
    alignItems: "center",
  },
  header: {
    alignItems: "center",
    marginBottom: 30,
  },
  title: {
    fontSize: 36,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
    marginBottom: 10,
    textShadowColor: "#00ff88",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 15,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    textAlign: "center",
  },
  statsBar: {
    flexDirection: "row",
    backgroundColor: "rgba(26, 31, 58, 0.8)",
    borderRadius: 15,
    padding: 20,
    marginHorizontal: 20,
    marginBottom: 40,
    borderWidth: 2,
    borderColor: "#00ff88",
  },
  statItem: {
    flex: 1,
    alignItems: "center",
  },
  statLabel: {
    fontSize: 10,
    fontFamily: "PressStart2P_400Regular",
    color: "#888",
    marginBottom: 5,
  },
  statValue: {
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
  },
  statDivider: {
    width: 2,
    backgroundColor: "#333",
    marginHorizontal: 10,
  },
  islandsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    paddingHorizontal: 10,
  },
  islandContainer: {
    width: width * 0.42,
    margin: 10,
  },
  island: {
    borderRadius: 20,
    padding: 20,
    alignItems: "center",
    borderWidth: 3,
    borderColor: "#fff",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.5,
    shadowRadius: 15,
    elevation: 10,
  },
  islandEmoji: {
    fontSize: 48,
    marginBottom: 10,
  },
  islandTitle: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
    marginBottom: 5,
    textShadowColor: "#000",
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 0,
  },
  islandSubtitle: {
    fontSize: 8,
    fontFamily: "PressStart2P_400Regular",
    color: "#fff",
    textAlign: "center",
    opacity: 0.8,
  },
});

