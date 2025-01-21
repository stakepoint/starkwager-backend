import { registerAs } from '@nestjs/config';

export default registerAs('config', () => ({
  port: parseInt(process.env.SERVER_PORT, 10) || 8080,
  nodenv: process.env.NODE_ENV,
  secret: process.env.JWT_SECRET,
}));
