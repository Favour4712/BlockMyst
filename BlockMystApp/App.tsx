import "@walletconnect/react-native-compat";

import React, { useEffect } from "react";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, Text, View, Linking } from "react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { NavigationContainer } from "@react-navigation/native";
import { AppKitProvider, AppKit } from "@reown/appkit-react-native";
import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  useFonts,
  PressStart2P_400Regular,
} from "@expo-google-fonts/press-start-2p";

import { appKit, wagmiAdapter } from "./src/services/AppKitConfig";
import { GameProvider, useGame } from "./src/context/GameContext";
import GameNavigator from "./src/navigation/GameNavigator";
import WalletConnectButton from "./src/components/WalletConnectButton";

// Create QueryClient instance
const queryClient = new QueryClient();

// Deep link handler component
function DeepLinkHandler() {
  useEffect(() => {
    const handleDeepLink = ({ url }: { url: string }) => {
      console.log("Deep link received:", url);
      // AppKit will handle the wallet connection automatically
    };

    // Listen for deep links
    const subscription = Linking.addEventListener("url", handleDeepLink);

    // Check if app was opened with a deep link
    Linking.getInitialURL().then((url) => {
      if (url) {
        handleDeepLink({ url });
      }
    });

    return () => {
      subscription.remove();
    };
  }, []);

  return null;
}

// Landing Screen Component
function LandingScreen({ onStart }: { onStart: () => void }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>BLOCKMYST</Text>
      <Text style={styles.subtitle}>⚡ PUZZLE QUEST ⚡</Text>

      <WalletConnectButton onConnected={onStart} />

      <StatusBar style="light" />
    </View>
  );
}

// Main App Content
function AppContent() {
  const { isConnected, connect } = useGame();

  useEffect(() => {
    // Auto-connect with mock data
    connect();
  }, []);

  if (!isConnected) {
    return <LandingScreen onStart={connect} />;
  }

  return (
    <NavigationContainer>
      <GameNavigator />
      <StatusBar style="light" />
    </NavigationContainer>
  );
}

export default function App() {
  const [fontsLoaded] = useFonts({
    PressStart2P_400Regular,
  });

  if (!fontsLoaded) {
    return null; // Show nothing while fonts load
  }

  return (
    <SafeAreaProvider>
      <AppKitProvider instance={appKit}>
        <WagmiProvider config={wagmiAdapter.wagmiConfig}>
          <QueryClientProvider client={queryClient}>
            <GameProvider>
              <DeepLinkHandler />
              <AppContent />

              {/* AppKit Modal */}
              <AppKit />
            </GameProvider>
          </QueryClientProvider>
        </WagmiProvider>
      </AppKitProvider>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0a0e27",
    alignItems: "center",
    justifyContent: "center",
    padding: 20,
  },
  title: {
    fontSize: 32,
    fontFamily: "PressStart2P_400Regular",
    color: "#00ff88",
    marginBottom: 20,
    textShadowColor: "#00ff88",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 10,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 14,
    fontFamily: "PressStart2P_400Regular",
    color: "#ffd700",
    marginBottom: 50,
    textAlign: "center",
    textShadowColor: "#ffd700",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 8,
  },
});
