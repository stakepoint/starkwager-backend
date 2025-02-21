import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import  { CreateNotificationDto } from '../dtos/notification.dto';

@Injectable()
export class NotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async createNotification(data: CreateNotificationDto) {
    const { userId, isRead, message, type} = data
    return await this.prisma.notification.create({ data:{
       userId,
       message,
       type,
       isRead
    }
    })
  }

}
