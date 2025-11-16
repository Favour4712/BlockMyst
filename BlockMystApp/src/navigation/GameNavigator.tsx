import React from "react";
import { createStackNavigator } from "@react-navigation/stack";
import IslandHubScreen from "../screens/IslandHubScreen";
import PuzzleScreen from "../screens/PuzzleScreen";
import LeaderboardScreen from "../screens/LeaderboardScreen";
import ProfileScreen from "../screens/ProfileScreen";
import BattleRoyaleScreen from "../screens/BattleRoyaleScreen";
import GuildScreen from "../screens/GuildScreen";

export type GameStackParamList = {
  IslandHub: undefined;
  Puzzle: { puzzleId: number; difficulty: string };
  Leaderboard: undefined;
  Profile: undefined;
  BattleRoyale: undefined;
  Guild: undefined;
};

const Stack = createStackNavigator<GameStackParamList>();

export default function GameNavigator() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
        cardStyle: { backgroundColor: "#0a0e27" },
      }}
    >
      <Stack.Screen name="IslandHub" component={IslandHubScreen} />
      <Stack.Screen name="Puzzle" component={PuzzleScreen} />
      <Stack.Screen name="Leaderboard" component={LeaderboardScreen} />
      <Stack.Screen name="Profile" component={ProfileScreen} />
      <Stack.Screen name="BattleRoyale" component={BattleRoyaleScreen} />
      <Stack.Screen name="Guild" component={GuildScreen} />
    </Stack.Navigator>
  );
}

