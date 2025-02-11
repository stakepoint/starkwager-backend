import { Test, TestingModule } from '@nestjs/testing';
import { WagerInvitationService } from './wagerInvitation.service';

describe('WagerInvitationService', () => {
  let service: WagerInvitationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [WagerInvitationService],
    }).compile();

    service = module.get<WagerInvitationService>(WagerInvitationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
