import { Test, TestingModule } from '@nestjs/testing';
import { IndexerController } from './indexer.controller';
import { IndexerService } from './indexer.service';

describe('IndexerController', () => {
  let controller: IndexerController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [IndexerController],
      providers: [IndexerService],
    }).compile();

    controller = module.get<IndexerController>(IndexerController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
