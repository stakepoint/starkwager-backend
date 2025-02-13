import { Test, TestingModule } from '@nestjs/testing';
import { WagerInvitationService } from '../services/wagerInvitation.service';
import { WagerInvitationController } from './wagerInvitation.controller';

describe('WagerInvitationController', () => {
  let controller: WagerInvitationController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [WagerInvitationController],
      providers: [WagerInvitationService],
    }).compile();

    controller = module.get<WagerInvitationController>(
      WagerInvitationController,
    );
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
