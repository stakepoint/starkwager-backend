import { Test, TestingModule } from '@nestjs/testing';
import { WagerClaimService } from './wager-claim.service';
import { PrismaService } from 'nestjs-prisma';
import { BadRequestException } from '@nestjs/common';

describe('WagerClaimService', () => {
  let service: WagerClaimService;

  const mockPrismaService = {
    wager: {
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    wagerClaim: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WagerClaimService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<WagerClaimService>(WagerClaimService);
    // mockPrismaService = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a successful claim', async () => {
    const dto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };
    mockPrismaService.wager.findUnique.mockResolvedValue({
      id: '1',
      status: 'active',
    });
    mockPrismaService.wagerClaim.findUnique.mockResolvedValue(null);
    mockPrismaService.wagerClaim.create.mockResolvedValue({ id: '1', ...dto });

    const result = await service.createClaim(dto);

    expect(mockPrismaService.wagerClaim.create).toHaveBeenCalled();
    expect(mockPrismaService.wagerClaim.create).toHaveBeenCalledWith({
      data: dto,
    });

    expect(result).toEqual({ id: '1', ...dto });
  });

  it('should throw an error if wager is not found', async () => {
    const dto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };
    mockPrismaService.wager.findUnique.mockResolvedValue(null);

    await expect(service.createClaim(dto)).rejects.toThrow(
      new BadRequestException('Wager not found'),
    );
  });

  it('should throw an error if wager status is not active', async () => {
    const dto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };
    mockPrismaService.wager.findUnique.mockResolvedValue({
      id: '1',
      status: 'pending',
    });

    await expect(service.createClaim(dto)).rejects.toThrow(
      new BadRequestException('Only active wagers can be claimed'),
    );
  });

  it('should throw an error if wager has already been claimed', async () => {
    const dto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };
    mockPrismaService.wager.findUnique.mockResolvedValue({
      id: '1',
      status: 'active',
    });
    mockPrismaService.wagerClaim.findUnique.mockResolvedValue({ id: '1' });

    await expect(service.createClaim(dto)).rejects.toThrow(
      new BadRequestException('This wager has already been claimed'),
    );
  });

  it('should accept a claim', async () => {
    const claimId = '1';
    const wagerId = '1';

    mockPrismaService.wagerClaim.findUnique.mockResolvedValue({
      id: claimId,
      wagerId,
    });
    mockPrismaService.wager.findUnique.mockResolvedValue({
      id: wagerId,
      status: 'active',
    });

    mockPrismaService.wager.update.mockResolvedValue({
      id: wagerId,
      status: 'completed',
    });

    mockPrismaService.wagerClaim.update.mockResolvedValue({
      id: claimId,
      status: 'accepted',
    });

    const result = await service.acceptClaim(claimId);

    expect(mockPrismaService.wager.update).toHaveBeenCalled();
    expect(mockPrismaService.wager.update).toHaveBeenCalledWith({
      where: { id: wagerId },
      data: { status: 'completed' },
    });

    expect(mockPrismaService.wagerClaim.update).toHaveBeenCalled();
    expect(mockPrismaService.wagerClaim.update).toHaveBeenCalledWith({
      where: { id: claimId },
      data: { status: 'accepted' },
    });

    expect(result.status).toBe('accepted');
  });

  it('should throw an error if wager claim is not found', async () => {
    const claimId = '1';

    mockPrismaService.wagerClaim.findUnique.mockResolvedValue(null);
    await expect(service.acceptClaim(claimId)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('should throw an error if wager is not active', async () => {
    const claimId = '1';
    const wagerId = '1';
    const claim = {
      id: '1',
      wagerId,
    };
    mockPrismaService.wagerClaim.findUnique.mockResolvedValue(claim);
    mockPrismaService.wager.findUnique.mockResolvedValue({
      id: wagerId,
      status: 'pending',
    });

    await expect(service.acceptClaim(claimId)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('should reject a claim with a valid proofLink', async () => {
    const dto = {
      id: '1',
      reason: 'Not valid',
      status: 'rejected',
      proofLink: 'https://proof-link.com',
      proofFile: null,
    };

    mockPrismaService.wagerClaim.findUnique.mockResolvedValue({
      id: '1',
      status: 'pending',
    });
    mockPrismaService.wagerClaim.update.mockResolvedValue(dto);

    const result = await service.rejectClaim(dto);
    expect(result).toEqual(dto);
  });

  it('should throw an error if no proofLink or proofFile is provided', async () => {
    const dto = {
      id: '1',
      reason: 'Not valid',
      status: 'rejected',
      proofLink: null,
      proofFile: null,
    };

    await expect(service.rejectClaim(dto)).rejects.toThrow(BadRequestException);
  });

  it('should throw an error if proofLink is invalid', async () => {
    const dto = {
      id: '1',
      reason: 'Not valid',
      status: 'rejected',
      proofLink: 'invalid-link',
      proofFile: null,
    };

    expect(service.rejectClaim(dto)).rejects.toThrow(BadRequestException);
  });

  it('should throw an error if claim is not found', async () => {
    const dto = {
      id: '1',
      reason: 'Not valid',
      status: 'rejected',
      proofLink: 'https://proof-link.com',
      proofFile: null,
    };
    mockPrismaService.wagerClaim.findUnique.mockResolvedValue(null);
    await expect(service.rejectClaim(dto)).rejects.toThrow(BadRequestException);
  });

  it('should throw an error if wager claim status is not pending', async () => {
    const dto = {
      id: '1',
      reason: 'Not valid',
      status: 'rejected',
      proofLink: 'https://proof-link.com',
      proofFile: null,
    };

    mockPrismaService.wagerClaim.findUnique.mockResolvedValue({
      id: '1',
      status: 'accepted',
    });
    await expect(service.rejectClaim(dto)).rejects.toThrow(BadRequestException);
  });
});
