import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import  { CreateNotificationDto } from '../dtos/notification.dto';

@Injectable()
export class NotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async createNotification(userId: string, data: CreateNotificationDto) {
    const {isRead, message, type} = data
     const notification = await this.prisma.notification.create({ data:{
       userId,
       message,
       type,
       isRead
    }
    })
    return {data: notification}
  }

  async getNotifications(userId: string, isRead?: boolean){
    const notifications = await this.prisma.notification.findMany({where: {userId, isRead}})
    return {data: notifications, totalcount: notifications.length }
  }


  async markAsRead(id: string) {  
    const notification = await this.prisma.notification.findUnique({ where: { id } });
  
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
      const updated = await this.prisma.notification.update({
      where: { id },  
      data: { isRead: true }, 
    });
    return {isRead: updated.isRead, message: 'marked'}
  }

  async deleteNotification(id: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    await this.prisma.notification.delete({ where: { id } });
    return {data: true, message: 'Deleted'}
  }

async getANotification(id: string, userId: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id, userId } });

    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    return {data: notification};
  }
 }
