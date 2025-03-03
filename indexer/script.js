export const config = {
  streamUrl: Deno.env.get("APIBARA_STREAM_URL"),
  startingBlock: 0,
  network: "starknet",
  finality: "DATA_STATUS_PENDING",
  filter: {
    events: [
      {
        // Dummy Event Simulation
        fromAddress: Deno.env.get("DUMMY_CONTRACT_ADDRESS"),
        keys: [
          "0x00df776faf675d0c64b0f2ec596411cf1509d3966baba3478c84771ddbac1784",
        ],
        includeReverted: false,
        includeTransaction: false,
        includeReceipt: false,
      },
    ],
  },
  sinkType: "webhook",
  sinkOptions: {
    targetUrl: Deno.env.get("EVENT_TARGET_URL"),
  },
};

export default function transform(block) {
  return block;
}
