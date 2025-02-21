import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import  { CreateNotificationDto, UpdateNotificationDto } from '../dtos/notification.dto';

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
      throw new NotFoundException('User not found');
    }
    const notifications = await this.prisma.notification.findMany({where: {userId, isRead}})
    if(!notifications || notifications.length === 0){
      return []
    }

    return {data: notifications, totalcount: notifications.length }
  }


  async markAsRead(id: string, dto: UpdateNotificationDto) {
    const { isRead } = dto;
  
    const notification = await this.prisma.notification.findUnique({ where: { id } });
  
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
      return this.prisma.notification.update({
      where: { id },  
      data: { isRead }, 
    });
  }
  }
