import { Test, TestingModule } from '@nestjs/testing';
import { HashtagsService } from '../src/hashtags/hashtags.service';
import { PrismaService } from '../src/prisma/prisma.service';

describe('HashtagsService', () => {
    let service: HashtagsService;
    let prisma: PrismaService;

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [HashtagsService, PrismaService],
        }).compile();

        service = module.get<HashtagsService>(HashtagsService);
        prisma = module.get<PrismaService>(PrismaService);
    });

    it('should create a hashtag', async () => {
        jest.spyOn(prisma.hashtag, 'create').mockResolvedValue({ id: '1', name: 'NestJS', createdAt: new Date() });

        const result = await service.create('NestJS');
        expect(result.name).toBe('NestJS');
    });

    it('should find all hashtags', async () => {
        jest.spyOn(prisma.hashtag, 'findMany').mockResolvedValue([{ id: '1', name: 'NestJS', createdAt: new Date() }]);

        const result = await service.findAll();
        expect(result.length).toBe(1);
    });
});
