import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StoreProvider } from './src/contexts/StoreContext';
import { CartProvider } from './src/contexts/CartContext';
import { MainNavigator } from './src/navigation/MainNavigator';

export default function App() {
  return (
    <SafeAreaProvider>
      <StoreProvider>
        <CartProvider>
          <StatusBar style="dark" />
          <MainNavigator />
        </CartProvider>
      </StoreProvider>
    </SafeAreaProvider>
  );
}
