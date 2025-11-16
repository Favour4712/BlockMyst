module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      [
        'babel-preset-expo',
        {
          unstable_transformImportMeta: true, // Enable import.meta polyfill for Hermes
        },
      ],
    ],
    plugins: [
      'react-native-reanimated/plugin', // Must be last!
    ],
  };
};

