import AsyncStorage from "@react-native-async-storage/async-storage";
import type { Storage } from "@reown/appkit-react-native";

export const storage: Storage = {
  async getKeys(): Promise<string[]> {
    const keys = await AsyncStorage.getAllKeys();
    return [...keys]; // Return mutable copy
  },

  async getEntries<T = any>(): Promise<[string, T][]> {
    const keys = await this.getKeys();
    const entries = await AsyncStorage.multiGet(keys);
    return entries.map(
      ([key, value]) => [key, JSON.parse(value || "null")] as [string, T]
    );
  },

  async getItem<T = any>(key: string): Promise<T | undefined> {
    const value = await AsyncStorage.getItem(key);
    return value ? JSON.parse(value) : undefined;
  },

  async setItem<T = any>(key: string, value: T): Promise<void> {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  },

  async removeItem(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  },
};
