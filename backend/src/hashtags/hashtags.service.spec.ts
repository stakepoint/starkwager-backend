import { Test, TestingModule } from '@nestjs/testing';
import { HashtagsService } from './hashtags.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateHashtagDto } from './dto/create-hashtag.dto';

describe('HashtagsService', () => {
  let service: HashtagsService;
  let prisma: PrismaService;

  const mockHashtag = {
    id: '1',
    name: 'Test Hashtag',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HashtagsService,
        {
          provide: PrismaService,
          useValue: {
            hashtag: {
              create: jest.fn().mockResolvedValue(mockHashtag),
              findMany: jest.fn().mockResolvedValue([mockHashtag]),
            },
          },
        },
      ],
    }).compile();

    service = module.get<HashtagsService>(HashtagsService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a hashtag', async () => {
      const createHashtagDto: CreateHashtagDto = {
        name: 'Test Hashtag',
      };

      const result = await service.create(createHashtagDto);
      expect(prisma.hashtag.create).toHaveBeenCalledWith({
        data: createHashtagDto,
      });
      expect(result).toEqual(mockHashtag);
    });
  });

  describe('findAll', () => {
    it('should return all hashtags', async () => {
      const result = await service.findAll();
      expect(prisma.hashtag.findMany).toHaveBeenCalled();
      expect(result).toEqual([mockHashtag]);
    });
  });
});
