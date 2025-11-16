import React, { createContext, useContext, useState, ReactNode } from "react";

interface PlayerStats {
  username: string;
  address: string;
  level: number;
  experience: number;
  points: number;
  puzzlesSolved: number;
  rank: number;
  guild?: string;
  nfts: number;
}

interface GameContextType {
  isConnected: boolean;
  playerStats: PlayerStats;
  connect: () => Promise<void>;
  disconnect: () => void;
  updateStats: (stats: Partial<PlayerStats>) => void;
}

const GameContext = createContext<GameContextType | undefined>(undefined);

export function GameProvider({ children }: { children: ReactNode }) {
  const [isConnected, setIsConnected] = useState(false);
  const [playerStats, setPlayerStats] = useState<PlayerStats>({
    username: "",
    address: "",
    level: 1,
    experience: 0,
    points: 0,
    puzzlesSolved: 0,
    rank: 0,
    nfts: 0,
  });

  const connect = async () => {
    // Mock connection for now
    setIsConnected(true);
    setPlayerStats({
      username: "CryptoMaster",
      address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
      level: 12,
      experience: 2450,
      points: 8750,
      puzzlesSolved: 47,
      rank: 156,
      guild: "Cipher Knights",
      nfts: 8,
    });
  };

  const disconnect = () => {
    setIsConnected(false);
    setPlayerStats({
      username: "",
      address: "",
      level: 1,
      experience: 0,
      points: 0,
      puzzlesSolved: 0,
      rank: 0,
      nfts: 0,
    });
  };

  const updateStats = (stats: Partial<PlayerStats>) => {
    setPlayerStats((prev) => ({ ...prev, ...stats }));
  };

  return (
    <GameContext.Provider
      value={{ isConnected, playerStats, connect, disconnect, updateStats }}
    >
      {children}
    </GameContext.Provider>
  );
}

export function useGame() {
  const context = useContext(GameContext);
  if (!context) {
    throw new Error("useGame must be used within GameProvider");
  }
  return context;
}

