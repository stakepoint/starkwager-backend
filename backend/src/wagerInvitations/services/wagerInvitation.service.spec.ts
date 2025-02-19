import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from 'nestjs-prisma';
import { CreateWagerInvitationDto } from '../dtos/wagerInvitations.dto';
import { WagerInvitationService } from './wagerInvitation.service';

describe('WagerInvitationService', () => {
  let service: WagerInvitationService;
  let prisma: PrismaService;

  const mockInvitation = {
    id: '1',
    wagerId: '1',
    invitedById: '1',
    invitedUsername: 'testuser',
    status: 'pending',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WagerInvitationService,
        {
          provide: PrismaService,
          useValue: {
            invitation: {
              create: jest.fn().mockResolvedValue(mockInvitation),
              findMany: jest.fn().mockResolvedValue([mockInvitation]),
              findFirst: jest.fn().mockResolvedValue(mockInvitation),
            },
          },
        },
      ],
    }).compile();

    service = module.get<WagerInvitationService>(WagerInvitationService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createInvitation', () => {
    it('should create a wager invitation', async () => {
      const createInvitationDto: CreateWagerInvitationDto = {
        wagerId: '1',
        invitedUsername: 'testuser',
      };

      const invitedByUserId = '1';

      const result = await service.createInvitation(
        createInvitationDto,
        invitedByUserId,
      );
      expect(prisma.invitation.create).toHaveBeenCalledWith({
        data: {
          wagerId: '1',
          invitedById: '1',
          invitedUsername: 'testuser',
          status: 'pending',
        },
      });
      expect(result).toEqual(mockInvitation);
    });
  });

  describe('getInvitationsForWager', () => {
    it('should return invitations for a wager', async () => {
      const wagerId = '1';
      const invitedById = '1';

      const result = await service.getInvitationsForWager(wagerId, invitedById);
      expect(prisma.invitation.findMany).toHaveBeenCalledWith({
        where: { wagerId, invitedById },
        include: { invitedUser: true, wager: true },
      });
      expect(result).toEqual([mockInvitation]);
    });
  });

  describe('findExistingInvitation', () => {
    it('should return an existing invitation', async () => {
      const wagerId = '1';
      const invitedUsername = 'testuser';

      const result = await service.findExistingInvitation(
        wagerId,
        invitedUsername,
      );
      expect(prisma.invitation.findFirst).toHaveBeenCalledWith({
        where: { wagerId, invitedUsername },
      });
      expect(result).toEqual(mockInvitation);
    });

    it('should return null if no existing invitation is found', async () => {
      const wagerId = '1';
      const invitedUsername = 'nonexistentuser';

      jest.spyOn(prisma.invitation, 'findFirst').mockResolvedValue(null);

      const result = await service.findExistingInvitation(
        wagerId,
        invitedUsername,
      );
      expect(prisma.invitation.findFirst).toHaveBeenCalledWith({
        where: { wagerId, invitedUsername },
      });
      expect(result).toBeNull();
    });
  });
});
