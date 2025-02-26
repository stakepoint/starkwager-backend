import { Test, TestingModule } from '@nestjs/testing';
import { NotificationService } from './notification.service';
import { PrismaService } from 'nestjs-prisma';
import { CreateNotificationDto } from '../dtos/notification.dto';
import { NotificationType } from '@prisma/client';

describe('NotificationService', () => {
  let service: NotificationService;
  let prisma: PrismaService;

  const mockNotification = {
    id: '1',
    message: 'Test Message',
    type: NotificationType.general,
    userId: '1',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        {
          provide: PrismaService,
          useValue: {
            notification: {
              create: jest.fn().mockResolvedValue(mockNotification),
              findMany: jest.fn().mockResolvedValue([mockNotification]),
              findUnique: jest.fn().mockResolvedValue(mockNotification),
            },
          },
        },
      ],
    }).compile();

    service = module.get<NotificationService>(NotificationService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createNotification', () => {
    it('should create a notification', async () => {
      const createNotificationDto: CreateNotificationDto = {
        message: mockNotification.message,
        type: mockNotification.type,
      };

      const result = await service.createNotification(
        '1',
        createNotificationDto,
      );
      expect(prisma.notification.create).toHaveBeenCalledWith({
        data: createNotificationDto,
      });
      expect(result).toEqual(mockNotification);
    });
  });
});
