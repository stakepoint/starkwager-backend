import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class IndexerService {
  constructor(private prisma: PrismaService) {}

  async consumeIndexerMsg(message: any) {
    const { cursor, endCursor, finality, batch } = message.data;

    // Save the message to the database
    const savedMessage = await this.prisma.indexerMessage.create({
      data: {
        cursor: {
          connectOrCreate: {
            where: { orderKey: cursor.orderKey },
            create: {
              orderKey: cursor.orderKey,
              uniqueKey: cursor.uniqueKey,
            },
          },
        },
        endCursor: {
          connectOrCreate: {
            where: { orderKey: endCursor.orderKey },
            create: {
              orderKey: endCursor.orderKey,
              uniqueKey: endCursor.uniqueKey,
            },
          },
        },
        finality,
        batch,
      },
    });

    // Process and save events
    for (const event of batch[0].events) {
      await this.processEvent(event, cursor.orderKey);
    }

    return savedMessage;
  }

  private async processEvent(event: any, cursorOrderKey: number) {
    const { fromAddress, keys, data } = event.event;

    // Save the event to the database
    await this.prisma.indexerEvent.create({
      data: {
        fromAddress,
        keys,
        data,
        cursor: {
          connect: { orderKey: cursorOrderKey },
        },
      },
    });

    // Map event keys to their respective handlers
    const eventProcessors = {
      '0x00df776faf675d0c64b0f2ec596411cf1509d3966baba3478c84771ddbac1784':
        this.dummyEvent,
    };

    const processor = eventProcessors[keys[0]];
    if (processor) {
      await processor(event);
    } else {
      console.error(`No processor found for event key: ${keys[0]}`);
    }
  }

  private async dummyEvent(event: any) {
    console.log('Processing New Day Event:', event);
  }
}
