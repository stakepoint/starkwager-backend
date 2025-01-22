export default () => ({
  redis: {
    url: `${process.env.REDIS_HOST}:${process.env.REDIS_PORT}`,
    type: 'single',
    options: {
      password: process.env.REDIS_PASSWORD,
      username: process.env.REDIS_USERNAME,
    },
  },
});
