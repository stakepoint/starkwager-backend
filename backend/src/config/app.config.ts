import { registerAs } from '@nestjs/config';

export default registerAs('APP_CONFIG', () => ({
  port: parseInt(process.env.SERVER_PORT ?? '8080', 10),
  nodenv: process.env.NODE_ENV ?? 'development',
  secret: process.env.JWT_SECRET,
  refreshTokenSecret: process.env.REFRESH_TOKEN_SECRET,
  accessTokenExpiry: process.env.JWT_ACCESS_EXPIRTY_TIME,
  refreshTokenExpiry: process.env.JWT_REFRESH_EXPIRTY_TIME,
  nodeUrl: process.env.NODE_URL,
  chainId: process.env.CHAIN_ID,
}));
