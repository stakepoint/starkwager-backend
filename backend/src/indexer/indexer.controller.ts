import { Controller, Post, Body } from '@nestjs/common';
import { IndexerService } from './indexer.service';

@Controller('indexer')
export class IndexerController {
  constructor(private readonly indexerService: IndexerService) {}

  @Post('consume-indexer-msg')
  async consumeIndexerMsg(@Body() message: any) {
    await this.indexerService.consumeIndexerMsg(message);
    return { status: 'Message processed' };
  }
}
