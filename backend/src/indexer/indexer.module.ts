import { Module } from '@nestjs/common';
import { IndexerService } from './indexer.service';
import { IndexerController } from './indexer.controller';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  controllers: [IndexerController],
  providers: [IndexerService, PrismaService],
})
export class IndexerModule {}
