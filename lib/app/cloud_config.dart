/// Where the app gets catalogue updates. Only the catalogue and photos are
/// downloaded from here; nothing about the user is sent.
const gustaroApi = String.fromEnvironment(
  'GUSTARO_API',
  defaultValue: 'https://api-production-a5ba0.up.railway.app',
);
