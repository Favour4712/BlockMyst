import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useAppKit } from "@reown/appkit-react-native";
import { useAccount } from "wagmi";
import {
  useFonts,
  PressStart2P_400Regular,
} from "@expo-google-fonts/press-start-2p";

export default function WalletConnectButton() {
  const { open } = useAppKit();
  const { address, isConnected } = useAccount();

  const [fontsLoaded] = useFonts({
    PressStart2P_400Regular,
  });

  if (!fontsLoaded) {
    return null;
  }

  if (isConnected && address) {
    return (
      <View style={styles.connectedContainer}>
        <Text style={styles.connectedText}>⚡ READY ⚡</Text>
        <Text style={styles.addressText}>
          {address.slice(0, 6)}...{address.slice(-4)}
        </Text>
        <TouchableOpacity style={styles.startButton} onPress={() => open()}>
          <Text style={styles.buttonText}>▶ START GAME</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <TouchableOpacity style={styles.playButton} onPress={() => open()}>
      <Text style={styles.buttonText}>⚔️ PLAY NOW ⚔️</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  playButton: {
    backgroundColor: "#ff1744",
    paddingHorizontal: 40,
    paddingVertical: 20,
    borderRadius: 8,
    borderWidth: 4,
    borderColor: "#fff",
    shadowColor: "#ff1744",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.8,
    shadowRadius: 12,
    elevation: 10,
  },
  startButton: {
    backgroundColor: "#00ff88",
    paddingHorizontal: 30,
    paddingVertical: 15,
    borderRadius: 8,
    borderWidth: 3,
    borderColor: "#fff",
    marginTop: 15,
    shadowColor: "#00ff88",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.6,
    shadowRadius: 10,
  },
  buttonText: {
    color: "#fff",
    fontSize: 16,
    fontFamily: "PressStart2P_400Regular",
    textAlign: "center",
    textShadowColor: "#000",
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 0,
  },
  connectedContainer: {
    alignItems: "center",
    padding: 25,
    backgroundColor: "#1a1f3a",
    borderRadius: 12,
    borderWidth: 4,
    borderColor: "#00ff88",
    shadowColor: "#00ff88",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 15,
  },
  connectedText: {
    color: "#00ff88",
    fontSize: 18,
    fontFamily: "PressStart2P_400Regular",
    marginBottom: 15,
    textShadowColor: "#00ff88",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 8,
  },
  addressText: {
    color: "#ffd700",
    fontSize: 12,
    fontFamily: "PressStart2P_400Regular",
    marginBottom: 5,
  },
});
