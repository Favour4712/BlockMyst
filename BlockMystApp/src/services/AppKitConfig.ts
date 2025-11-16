import "@walletconnect/react-native-compat";

import { createAppKit } from "@reown/appkit-react-native";
import { WagmiAdapter } from "@reown/appkit-wagmi-react-native";
import { celoSepolia } from "viem/chains";
import { storage } from "./StorageUtil";

const projectId = "4dff344bfed4ca9ba39084e58490eb9d";

// Configure Wagmi adapter with Celo Sepolia testnet
export const wagmiAdapter = new WagmiAdapter({
  projectId,
  networks: [celoSepolia], // Celo Sepolia testnet
});

// Create AppKit instance
export const appKit = createAppKit({
  projectId,
  adapters: [wagmiAdapter],
  networks: [celoSepolia],
  defaultNetwork: celoSepolia,
  storage,
  metadata: {
    name: "BlockMyst",
    description: "Blockchain Puzzle Game on Celo",
    url: "https://blockmyst.app",
    icons: ["https://blockmyst.app/icon.png"],
    redirect: {
      native: "blockmyst://",
      universal: "https://blockmyst.app",
      linkMode: true, // Enable Link Mode for direct wallet connections
    },
  },
  features: {
    email: true, // Enable email login
    socials: ["email", "google", "x", "discord", "apple", "github", "facebook"], // Email first!
    emailShowWallets: true, // Show wallet options
    swaps: false, // Disable swaps for now
    onramp: false, // Disable onramp for now
  },
});
