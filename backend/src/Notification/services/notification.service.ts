import { BadRequestException, Injectable } from '@nestjs/common';
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

  async getNotifications(userId: string, isRead?: boolean){
    const user = await this.prisma.user.findUnique({where:{id: userId}})
    if(!user){
      throw new BadRequestException('User does not exist');
    }
    const notifications = await this.prisma.notification.findMany({where: {userId, isRead}})
    if(!notifications || notifications.length === 0){
      return []
    }

    return {data: notifications, totalcount: notifications.length }
  }

}
